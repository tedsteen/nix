#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo "this script must be run as root" >&2
  exit 1
fi

BACKUP_FILE="docker-volumes-$(date +%F-%H%M).tar.gz"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

VOLUME_LIST="$TMP_DIR/volumes.txt"
MOUNTPOINTS_DIR="$TMP_DIR/mounts"

mkdir -p "$MOUNTPOINTS_DIR"

# remember which containers were running
RUNNING_CONTAINERS=$(docker ps -q)

echo "[+] stopping all containers..."
if [ -n "$RUNNING_CONTAINERS" ]; then
  docker stop $RUNNING_CONTAINERS >/dev/null
fi

echo "[+] gathering volume info..."
docker volume ls -q > "$VOLUME_LIST"

# mount each volume into the tmp dir
while read -r volume; do
  mountpoint=$(docker volume inspect --format '{{ .Mountpoint }}' "$volume")
  ln -s "$mountpoint" "$MOUNTPOINTS_DIR/$volume"
done < "$VOLUME_LIST"

echo "[+] creating archive..."
tar czpf "$BACKUP_FILE" --numeric-owner --dereference -C "$MOUNTPOINTS_DIR" . 

echo "[+] backup complete: $BACKUP_FILE"

# restart previously running containers
if [[ -n "$RUNNING_CONTAINERS" ]]; then
  echo "[+] restarting containers..."
  docker start $RUNNING_CONTAINERS >/dev/null
fi
