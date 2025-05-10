#!/bin/bash
export TARGET_HOST="${1:-"nixos@<missing-ip>"}"
export MACHINE=${2:-"./linux-machines/pinheiro/nuc"}

nix run github:nix-community/nixos-anywhere/1.9.0 --extra-experimental-features "nix-command flakes" -- --generate-hardware-config nixos-generate-config $MACHINE/hardware-configuration.nix --flake $MACHINE#default --build-on remote $TARGET_HOST --target-host $TARGET_HOST
