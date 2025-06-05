#!/bin/bash
export TARGET_HOST="${1:-"nixos@<missing-ip>"}"
export MACHINE=${2:-"./lab"}

export NIX_CONFIG="extra-experimental-features = nix-command flakes"
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config "$MACHINE/hardware-configuration.nix" \
  --flake "$MACHINE#default" \
  --build-on remote "$TARGET_HOST" \
  --target-host "$TARGET_HOST"