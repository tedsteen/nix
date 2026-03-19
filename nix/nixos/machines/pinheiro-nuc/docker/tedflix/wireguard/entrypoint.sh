#!/bin/sh
set -euo pipefail

WG_IF=wg0
KILLSWITCH_CHAIN=wg-killswitch
LAN_IF=$(ip route show default | awk '/default/ { print $5; exit }')
LAN_SUBNET=$(ip -o -4 route show dev "$LAN_IF" proto kernel scope link | awk 'NR == 1 { print $1 }')

delete_killswitch() {
    iptables -D OUTPUT -j "$KILLSWITCH_CHAIN" 2>/dev/null || true
    iptables -F "$KILLSWITCH_CHAIN" 2>/dev/null || true
    iptables -X "$KILLSWITCH_CHAIN" 2>/dev/null || true
}

install_killswitch() {
    FWMARK=$(wg show "$WG_IF" fwmark)
    if [ "$FWMARK" = "off" ]; then
        echo "WireGuard fwmark is required for the VPN kill switch" >&2
        exit 1
    fi

    delete_killswitch
    iptables -N "$KILLSWITCH_CHAIN"

    iptables -A "$KILLSWITCH_CHAIN" -o lo -j RETURN
    iptables -A "$KILLSWITCH_CHAIN" -o "$WG_IF" -j RETURN
    iptables -A "$KILLSWITCH_CHAIN" -m mark --mark "$FWMARK" -j RETURN
    [ -n "$LAN_SUBNET" ] && iptables -A "$KILLSWITCH_CHAIN" -o "$LAN_IF" -d "$LAN_SUBNET" -j RETURN
    iptables -A "$KILLSWITCH_CHAIN" -j REJECT
    iptables -I OUTPUT 1 -j "$KILLSWITCH_CHAIN"
}

wg-quick up wg0
install_killswitch

finish () {
    delete_killswitch
    wg-quick down "$WG_IF"
    exit 0
}
trap finish TERM INT QUIT

sleep infinity &
wait $!
