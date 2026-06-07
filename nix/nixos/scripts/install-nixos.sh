#!/usr/bin/env bash
# Installs NixOS on a remote host using nixos-anywhere and stores the generated
# hardware config in nix/nixos/machines/<machine>/hardware-configuration.nix.
#
# Usage:
#   ./nix/nixos/scripts/install-nixos.sh <target_host> <machine_name>
# Example:
#   ./nix/nixos/scripts/install-nixos.sh root@1.2.3.4 pinheiro-nuc
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

if ! command -v nix >/dev/null 2>&1; then
  echo "nix is required but not found in PATH"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NIXOS_FLAKE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
FLAKE="git+file:${REPO_ROOT}?dir=nix/nixos#${MACHINE_NAME}"
MACHINE_DIR="${NIXOS_FLAKE_DIR}/machines/${MACHINE_NAME}"
MACHINE_CONFIG_PATH="${MACHINE_DIR}/default.nix"
HARDWARE_CONFIG_PATH="${MACHINE_DIR}/hardware-configuration.nix"

if [ ! -f "${MACHINE_CONFIG_PATH}" ]; then
  echo "Machine config not found: ${MACHINE_CONFIG_PATH}"
  exit 1
fi

echo "==> Installing NixOS on ${TARGET_HOST}"
echo "==> Writing generated hardware config to ${HARDWARE_CONFIG_PATH}"

nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config "${HARDWARE_CONFIG_PATH}" \
  --build-on remote \
  --flake "${FLAKE}" \
  "${TARGET_HOST}"

echo "==> NixOS installed"
