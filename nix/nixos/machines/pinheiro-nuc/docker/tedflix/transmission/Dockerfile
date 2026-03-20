FROM linuxserver/transmission:4.1.1

RUN apk add --no-cache wireguard-tools iproute2 iptables curl

# Prevent wg-quick from failing when the required sysctl is already set by Docker.
RUN sed -i 's/cmd sysctl -q \(.*\?\)=\(.*\)/[[ "$(sysctl -n \1)" != "\2" ]] \&\& \0/' /usr/bin/wg-quick

COPY root/ /

RUN chmod +x /etc/cont-init.d/09-wireguard.sh && \
    chmod +x /etc/cont-init.d/10-prepare-transmission.sh && \
    chmod +x /tedflix/update-settings.sh

RUN echo "0 0 1 * * /tedflix/update-settings.sh 2>&1" >> /etc/crontabs/abc
