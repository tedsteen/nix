#!/bin/bash
IP=${1:-"<missing-ip>"}
USER=${2:-"ted"}
export MACHINE=${3:-"./machines/pinheiro"}
export CONFIG=${4:-"nuc"}

export TARGET_HOST="$USER@$IP"

nix-shell -p '(nixos{}).nixos-rebuild' git --run "nixos-rebuild --fast --build-host $TARGET_HOST --use-remote-sudo --flake $MACHINE#$CONFIG --target-host $TARGET_HOST switch"

