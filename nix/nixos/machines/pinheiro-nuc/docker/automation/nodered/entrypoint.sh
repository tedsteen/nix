#!/bin/bash
set -euo pipefail

cp /usr/src/pinheiro-node-red/package.json /data/package.json
npm install --prefix /data --omit=dev --no-update-notifier --no-fund

cd /usr/src/node-red
exec ./entrypoint.sh "$@"
