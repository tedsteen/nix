#!/bin/bash
export TARGET_HOST="${1:-"ted@<missing-ip>"}"
export MACHINE=${2:-"./pinheiro/nuc"}

nix-shell -p '(nixos{}).nixos-rebuild' git --run "nixos-rebuild --fast --build-host $TARGET_HOST --use-remote-sudo --flake $MACHINE#default --target-host $TARGET_HOST switch"
