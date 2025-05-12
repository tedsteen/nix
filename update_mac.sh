#!/bin/bash
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- --extra-experimental-features "nix-command flakes" switch --flake path:./home-manager#tedsteen