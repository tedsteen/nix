#!/usr/bin/env bash
set -e
CMD=$1
# Default path for TEDFLIX if not set
export TEDFLIX_PATH=${TEDFLIX_PATH:-"/mnt/mediapool/tedflix"}

# Make sure the initial directory structure is set up with the right permissions
if [ ! -d $TEDFLIX_PATH ]; then
  mkdir -p $TEDFLIX_PATH/downloads/{complete,incomplete,manual} $TEDFLIX_PATH/movies $TEDFLIX_PATH/tv
  chown -R 1000:1000 $TEDFLIX_PATH
fi

export COMPOSE_BAKE=true
case "$CMD" in
    up)
        docker-compose -f tedflix/docker-compose.yaml pull
        docker-compose -f tedflix/docker-compose.yaml up -d --build --remove-orphans
        ;;
    down)
        docker-compose -f tedflix/docker-compose.yaml down
        ;;
    restart)
        docker-compose -f tedflix/docker-compose.yaml restart
        ;;
    *)
        echo "Usage: $0 up|down|restart"
        exit 1
        ;;
esac

exit 0