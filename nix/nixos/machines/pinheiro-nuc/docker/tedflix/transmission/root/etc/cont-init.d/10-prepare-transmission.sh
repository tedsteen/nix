#!/usr/bin/with-contenv sh
set -eu

if [ -n "${DEFAULT_GATEWAY:-}" ]; then
  LAN_GW=$(ip route show default | awk '/default/ { print $3; exit }')
  echo "Switch default gateway: $LAN_GW  →  $DEFAULT_GATEWAY"
  ip route replace default via "$DEFAULT_GATEWAY"

  # Which dev now carries that GW?
  VPN_IF=$(ip route get "$DEFAULT_GATEWAY" | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')

  [ -n "$VPN_IF" ] || { echo "No iface for $DEFAULT_GATEWAY" >&2; exit 1; }

  echo "RPC shield: blocking port 9091 on $VPN_IF (VPN path)"
  iptables -C INPUT -i "$VPN_IF" -p tcp --dport 9091 -j REJECT 2>/dev/null \
    || iptables -A INPUT -i "$VPN_IF" -p tcp --dport 9091 -j REJECT
fi

/tedflix/update-settings.sh
