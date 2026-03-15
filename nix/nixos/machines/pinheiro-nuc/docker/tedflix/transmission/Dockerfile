FROM linuxserver/transmission:4.1.1

RUN apk add --no-cache wireguard-tools-wg-quick iptables

COPY root/ /

RUN chmod +x /etc/cont-init.d/10-prepare-transmission.sh && \
    chmod +x /tedflix/update-settings.sh

RUN echo "0 0 1 * * /tedflix/update-settings.sh 2>&1" >> /etc/crontabs/abc
