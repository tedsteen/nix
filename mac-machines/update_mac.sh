#!/bin/bash
MAC_MACHINE=${1:-$(hostname)}
export NIX_CONFIG="extra-experimental-features = nix-command flakes"
nix run github:lnl7/nix-darwin -- switch --flake ./#$MAC_MACHINE