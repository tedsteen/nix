#!/usr/bin/with-contenv sh
set -e

LAN_GW=$(ip route show default | awk '/default/ {print $3}')
LAN_IF=$(ip route | awk -v gw="$LAN_GW" '$0~gw {print $5; exit}')
LAN_IP=$(ip -4 -o addr show dev "$LAN_IF" | awk '{sub(/\/.*/, "", $4); print $4}')
echo "$LAN_IP" > /run/lan_ip

if [[ -n "$DEFAULT_GATEWAY" ]]; then
  echo "Switch default gateway: $LAN_GW  →  $DEFAULT_GATEWAY"
  ip route replace default via "$DEFAULT_GATEWAY"
fi

/tedflix/update-settings.sh