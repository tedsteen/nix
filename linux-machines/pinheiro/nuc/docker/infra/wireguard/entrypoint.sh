#!/bin/sh
set -euo pipefail

WAN_IF=$(ip route show default | awk '/default/ {print $5}')
WG_IF="wg0"
WG_CONF="/etc/wireguard/wg0.conf"

echo "Starting Wireguard $WG_IF"
wg-quick up "$WG_IF"

echo 'Enabling source NAT'
iptables --table nat --append POSTROUTING --out-interface $WG_IF -j MASQUERADE
#iptables --append FORWARD --in-interface $WAN_IF -j ACCEPT
iptables -A FORWARD -i "$WAN_IF" -o "$WG_IF" -j ACCEPT
iptables -A FORWARD -i "$WG_IF" -o "$WAN_IF" -j ACCEPT

# Handle shutdown behavior
finish () {
    wg-quick down $WG_IF
    exit 0
}
trap finish TERM INT QUIT

sleep infinity &
wait $!