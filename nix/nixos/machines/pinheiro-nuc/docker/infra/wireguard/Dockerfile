FROM alpine:3.23

# Install wireguard-tools and iptables
RUN apk add wireguard-tools iptables curl

# Prevents wg-quick from attempting to set sysctl parameters that have already been set (preventing it from starting up).
RUN sed -i 's/cmd sysctl -q \(.*\?\)=\(.*\)/[[ "$(sysctl -n \1)" != "\2" ]] \&\& \0/' /usr/bin/wg-quick

COPY entrypoint.sh /run/entrypoint.sh

CMD ["/run/entrypoint.sh"]