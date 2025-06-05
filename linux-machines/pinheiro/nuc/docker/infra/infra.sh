#!/usr/bin/env bash
set -e
CMD=$1

export COMPOSE_BAKE=true
case "$CMD" in
    up)
        docker-compose -p infra pull
        docker-compose -p infra up -d --build --remove-orphans
        ;;
    down)
        docker-compose -p infra down
        ;;
    restart)
        docker-compose -p infra restart
        ;;
    *)
        echo "Usage: $0 up|down|restart"
        exit 1
        ;;
esac

exit 0