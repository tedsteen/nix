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

# Make sure we are relative to the script directory
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

case "$CMD" in
    up)
        docker compose -p tedflix up -d --build --remove-orphans
        ;;
    down)
        docker compose -p tedflix down
        ;;
    restart)
        docker compose -p tedflix restart
        ;;
    *)
        echo "Usage: $(basename "$0") up|down|restart"
        exit 1
        ;;
esac

exit 0