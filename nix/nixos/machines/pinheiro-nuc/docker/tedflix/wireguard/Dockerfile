FROM alpine:3.23

# Install the tooling needed to bring up WireGuard and program the kill switch.
RUN apk add wireguard-tools iproute2 iptables curl

# Prevents wg-quick from attempting to set sysctl parameters that have already been set (preventing it from starting up).
RUN sed -i 's/cmd sysctl -q \(.*\?\)=\(.*\)/[[ "$(sysctl -n \1)" != "\2" ]] \&\& \0/' /usr/bin/wg-quick

COPY entrypoint.sh /run/entrypoint.sh

CMD ["/run/entrypoint.sh"]
