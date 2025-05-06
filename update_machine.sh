#!/bin/bash
export TARGET_CONFIG=${1:-"test"}
export TARGET_HOST=${2:-"nixos"}@${3:-"<missing-ip>"}
nix-shell -p '(nixos{}).nixos-rebuild' git --run "nixos-rebuild --fast --build-host $TARGET_HOST --use-remote-sudo --flake ./$TARGET_CONFIG#$TARGET_CONFIG --target-host $TARGET_HOST switch"

