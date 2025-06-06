#!/usr/bin/env bash
set -e
CMD=$1

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
        echo "Usage: $0 up|down|restart"
        exit 1
        ;;
esac

exit 0