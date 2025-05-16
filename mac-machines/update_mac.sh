#!/bin/bash
export NIX_CONFIG="extra-experimental-features = nix-command flakes"
nix run github:lnl7/nix-darwin -- switch --flake ./#"teds-mbp"