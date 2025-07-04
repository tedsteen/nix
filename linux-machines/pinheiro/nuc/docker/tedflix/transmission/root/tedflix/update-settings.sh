#!/bin/sh
set -e

FILE=/config/settings.json
DOWNLOAD_DIR=/media/downloads/complete/$(date +"%y%m")
LAN_IP=$(cat /run/lan_ip)

echo "Updating '$FILE':"
echo "  DOWNLOAD_DIR='$DOWNLOAD_DIR'"
echo "  LAN_IP'$LAN_IP'"

cat <<EOF > $FILE
{
    "alt-speed-enabled": false,
    "announce-ip-enabled": false,
    "anti-brute-force-enabled": false,
    "blocklist-enabled": false,
    "cache-size-mb": 4,
    "default-trackers": "",
    "dht-enabled": true,
    "download-dir": "$DOWNLOAD_DIR",
    "download-queue-enabled": true,
    "download-queue-size": 5,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "/media/downloads/incomplete",
    "incomplete-dir-enabled": true,
    "lpd-enabled": false,
    "message-level": 2,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 200,
    "peer-limit-per-torrent": 50,
    "peer-port": 54995,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": true,
    "peer-socket-tos": "le",
    "pex-enabled": true,
    "port-forwarding-enabled": false,
    "preallocation": 1,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit-enabled": false,
    "rename-partial-files": false,
    "rpc-authentication-required": false,
    "rpc-bind-address": "$LAN_IP",
    "rpc-enabled": true,
    "rpc-host-whitelist-enabled": false,
    "rpc-port": 9091,
    "rpc-socket-mode": "0750",
    "rpc-url": "/transmission/",
    "rpc-username": "",
    "rpc-whitelist-enabled": false,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-added-enabled": false,
    "script-torrent-done-enabled": true,
    "script-torrent-done-filename": "/tedflix/unpack.sh",
    "script-torrent-done-seeding-enabled": false,
    "seed-queue-enabled": false,
    "speed-limit-down-enabled": false,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "tcp-enabled": true,
    "torrent-added-verify-mode": "fast",
    "trash-original-torrent-files": false,
    "umask": "002",
    "upload-slots-per-torrent": 14,
    "utp-enabled": false,
    "watch-dir-enabled": false
}
EOF

echo "soft-reload Transmission"
s6-svc -h /run/service/svc-transmission