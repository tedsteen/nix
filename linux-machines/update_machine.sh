#!/bin/bash
export TARGET_HOST="${1:-"ted@<missing-ip>"}"
export MACHINE=${2:-"./pinheiro/nuc"}

export NIX_CONFIG="extra-experimental-features = nix-command flakes"
nix run nixpkgs#nixos-rebuild -- \
  --fast \
  --flake "$MACHINE#default" \
  --build-host "$TARGET_HOST" \
  --target-host "$TARGET_HOST" \
  --use-remote-sudo \
  switch