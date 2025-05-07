#!/bin/bash
IP=${1:-"<missing-ip>"}
USER=${2:-"nixos"}
export MACHINE=${3:-"./machines/pinheiro"}
export CONFIG=${4:-"nuc"}

export TARGET_HOST="$USER@$IP"

nix run github:nix-community/nixos-anywhere/1.9.0 --extra-experimental-features "nix-command flakes" -- --generate-hardware-config nixos-generate-config $MACHINE/$CONFIG/hardware-configuration.nix --flake $MACHINE#$CONFIG --build-on remote $TARGET_HOST --target-host $TARGET_HOST
