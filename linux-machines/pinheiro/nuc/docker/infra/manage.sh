#!/usr/bin/env bash
set -e
CMD=$1

export INFRA_WIREGUARD_CONFIG=${INFRA_WIREGUARD_CONFIG:-"/run/secrets/infra_wireguard_config"}

# Make sure we are relative to the script directory
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

case "$CMD" in
    up)
        docker compose -p infra up -d --build --remove-orphans
        ;;
    down)
        docker compose -p infra down
        ;;
    start)
        docker compose -p infra start
        ;;
    stop)
        docker compose -p infra stop
        ;;
    restart)
        docker compose -p infra restart
        ;;
    *)
        echo "Usage: $(basename "$0") up|down|start|stop|restart"
        exit 1
        ;;
esac

exit 0