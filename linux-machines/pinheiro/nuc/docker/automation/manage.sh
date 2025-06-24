#!/usr/bin/env bash
set -e
CMD=$1

# Make sure we are relative to the script directory
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

case "$CMD" in
    up)
        docker compose -p automation up -d --build --remove-orphans
        ;;
    down)
        docker compose -p automation down
        ;;
    start)
        docker compose -p automation start
        ;;
    stop)
        docker compose -p automation stop
        ;;
    restart)
        docker compose -p automation restart
        ;;
    *)
        echo "Usage: $(basename "$0") up|down|start|stop|restart"
        exit 1
        ;;
esac

exit 0