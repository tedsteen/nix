#!/bin/bash
export TARGET_CONFIG=${1:-"test"}
export TARGET_HOST=${2:-"nixos"}@${3:-"<missing-ip>"}

nix run github:nix-community/nixos-anywhere/1.9.0 -- --generate-hardware-config nixos-generate-config ./$TARGET_CONFIG/hardware-configuration.nix --flake .#$TARGET_CONFIG --build-on remote $TARGET_HOST --target-host $TARGET_HOST
