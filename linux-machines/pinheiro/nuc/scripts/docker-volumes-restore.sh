#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo "this script must be run as root" >&2
  exit 1
fi

BACKUP_FILE="$1"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

echo "[+] extracting archive..."
tar xzpf "$BACKUP_FILE" -C "$TMP_DIR"

# remember which containers were running
RUNNING_CONTAINERS=$(docker ps -q)

echo "[+] stopping all containers..."
if [ -n "$RUNNING_CONTAINERS" ]; then
  docker stop $RUNNING_CONTAINERS >/dev/null
fi

for path in "$TMP_DIR"/*; do
  volume_name=$(basename "$path")
  echo "[+] restoring volume $volume_name"

  docker volume create "$volume_name" >/dev/null
  mountpoint=$(docker volume inspect --format '{{ .Mountpoint }}' "$volume_name")

  # copy files with correct perms and ownership
  tar cpf - -C "$path" . | tar xpf - -C "$mountpoint"
done

# restart previously running containers
if [[ -n "$RUNNING_CONTAINERS" ]]; then
  echo "[+] restarting containers..."
  docker start $RUNNING_CONTAINERS >/dev/null
fi
