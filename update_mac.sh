#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
FLAKE_ATTR="${1:-$(hostname)}"

exec nix run nix-darwin#darwin-rebuild -- switch --flake "git+file:${REPO_ROOT}?dir=nix/darwin#${FLAKE_ATTR}"
