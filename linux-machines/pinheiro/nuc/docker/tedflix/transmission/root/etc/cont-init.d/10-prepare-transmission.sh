#!/usr/bin/with-contenv sh
set -ex
wg-quick up wg0

/tedflix/update-settings.sh