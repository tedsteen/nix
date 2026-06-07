#!/usr/bin/env bash
# Applies a NixOS flake configuration to a remote host.
#
# Usage:
#   ./nix/nixos/scripts/apply-nixos-config.sh <target_host> <machine_name>
# Example:
#   ./nix/nixos/scripts/apply-nixos-config.sh ted@1.2.3.4 pinheiro-nuc
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <target_host> <machine_name>"
  exit 1
fi

TARGET_HOST="$1"
MACHINE_NAME="$2"

if [[ "${MACHINE_NAME}" == *"#"* ]]; then
  echo "Pass the machine name only, for example: pinheiro-nuc"
  exit 1
fi

if [ -z "${MACHINE_NAME}" ]; then
  echo "Machine name is empty. Expected: pinheiro-nuc"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
FLAKE="git+file:${REPO_ROOT}?dir=nix/nixos#${MACHINE_NAME}"

echo "==> Applying flake ${FLAKE} to ${TARGET_HOST} (mode: switch)"
nix run github:NixOS/nixpkgs/nixos-unstable#nixos-rebuild -- switch \
  --flake "${FLAKE}" \
  --target-host "${TARGET_HOST}" \
  --build-host "${TARGET_HOST}" \
  --sudo \
  --option accept-flake-config true

echo "==> Done"
