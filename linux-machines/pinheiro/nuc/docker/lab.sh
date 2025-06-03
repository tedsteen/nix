#!/usr/bin/env bash
set -e
CMD=$1

export COMPOSE_BAKE=true
case "$CMD" in
    up)
        docker-compose -f lab/docker-compose.yaml pull
        docker-compose -f lab/docker-compose.yaml up -d --build --remove-orphans
        ;;
    down)
        docker-compose -f lab/docker-compose.yaml down
        ;;
    restart)
        docker-compose -f lab/docker-compose.yaml restart
        ;;
    *)
        echo "Usage: $0 up|down|restart"
        exit 1
        ;;
esac

exit 0