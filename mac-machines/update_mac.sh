#!/bin/bash
nix run github:lnl7/nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ./#"teds-mbp"