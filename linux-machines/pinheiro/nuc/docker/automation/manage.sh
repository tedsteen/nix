#!/usr/bin/env bash
set -e
CMD=$1

# Make sure we are relative to the script directory
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export COMPOSE_BAKE=true
case "$CMD" in
    up)
        docker compose -p automation pull
        docker compose -p automation up -d --build --remove-orphans
        ;;
    down)
        docker compose -p automation down
        ;;
    restart)
        docker compose -p automation restart
        ;;
    *)
        echo "Usage: $(basename "$0") up|down|restart"
        exit 1
        ;;
esac

exit 0