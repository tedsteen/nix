#!/usr/bin/with-contenv sh
set -e
wg-quick up wg0

/tedflix/update-settings.sh