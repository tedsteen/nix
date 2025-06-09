#!/usr/bin/env bash
set -e
CMD=$1

# Make sure we are relative to the script directory
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export COMPOSE_BAKE=true
case "$CMD" in
    up)
        docker compose -p lab up -d --build --remove-orphans
        ;;
    down)
        docker compose -p lab down
        ;;
    restart)
        docker compose -p lab restart
        ;;
    *)
        echo "Usage: $(basename "$0") up|down|restart"
        exit 1
        ;;
esac

exit 0