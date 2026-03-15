#!/usr/bin/env bash
# Applies a NixOS flake configuration to a remote host.
#
# Usage:
#   ./nix/nixos/scripts/apply-nixos-config.sh <target_host> <flake>
# Example:
#   ./nix/nixos/scripts/apply-nixos-config.sh ted@1.2.3.4 ./#pinheiro-nuc
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <target_host> <flake>"
  exit 1
fi

TARGET_HOST="$1"
FLAKE="$2"

if [[ "${FLAKE}" != *"#"* ]]; then
  echo "FLAKE must include a machine target, for example: ./#pinheiro-nuc"
  exit 1
fi

MACHINE_NAME="${FLAKE#*#}"
if [ -z "${MACHINE_NAME}" ]; then
  echo "FLAKE target is empty. Expected: ./#pinheiro-nuc"
  exit 1
fi

echo "==> Applying flake ${FLAKE} to ${TARGET_HOST} (mode: switch)"
nix run nixpkgs#nixos-rebuild -- switch \
  --flake "${FLAKE}" \
  --target-host "${TARGET_HOST}" \
  --build-host "${TARGET_HOST}" \
  --sudo \
  --option accept-flake-config true

echo "==> Done"
