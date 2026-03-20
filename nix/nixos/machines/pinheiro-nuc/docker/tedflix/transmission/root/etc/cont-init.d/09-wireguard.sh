#!/usr/bin/with-contenv sh
set -eu

WG_IF=wg0
KILLSWITCH_CHAIN=wg-killswitch
LOCAL_ACCESS_SUBNETS="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10"
LAN_IF=""
LAN_SUBNET=""
LAN_GW=""

delete_killswitch() {
    iptables -D OUTPUT -j "$KILLSWITCH_CHAIN" 2>/dev/null || true
    iptables -F "$KILLSWITCH_CHAIN" 2>/dev/null || true
    iptables -X "$KILLSWITCH_CHAIN" 2>/dev/null || true
}

capture_lan_route_context() {
    # Grab the Docker-side route before wg-quick changes policy routing.
    LAN_IF=$(ip route show default | awk '/default/ { print $5; exit }')
    LAN_GW=$(ip route show default | awk '/default/ { print $3; exit }')

    [ -n "$LAN_IF" ] || return 0
    LAN_SUBNET=$(ip -o -4 route show dev "$LAN_IF" proto kernel scope link | awk 'NR == 1 { print $1 }')
}

install_local_access_routes() {
    [ -n "$LAN_IF" ] || return 0
    [ -n "$LAN_GW" ] || return 0

    for subnet in $LOCAL_ACCESS_SUBNETS; do
        ip route replace "$subnet" via "$LAN_GW" dev "$LAN_IF"
    done
}

add_killswitch_rule() {
    iptables -A "$KILLSWITCH_CHAIN" "$@"
}

install_killswitch() {
    FWMARK=$(wg show "$WG_IF" fwmark)
    if [ "$FWMARK" = "off" ]; then
        echo "WireGuard fwmark is required for the VPN kill switch" >&2
        exit 1
    fi

    delete_killswitch
    iptables -N "$KILLSWITCH_CHAIN"

    add_killswitch_rule -o lo -j RETURN
    add_killswitch_rule -o "$WG_IF" -j RETURN
    add_killswitch_rule -m mark --mark "$FWMARK" -j RETURN
    # Allow replies to inbound connections such as the Transmission UI published on the host.
    add_killswitch_rule -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
    [ -n "$LAN_SUBNET" ] && add_killswitch_rule -o "$LAN_IF" -d "$LAN_SUBNET" -j RETURN
    add_killswitch_rule -j REJECT
    iptables -I OUTPUT 1 -j "$KILLSWITCH_CHAIN"
}

capture_lan_route_context
wg-quick up "$WG_IF"
install_local_access_routes
install_killswitch
