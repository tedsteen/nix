#!/usr/bin/env bash
# Installs NixOS on a remote host using nixos-anywhere and stores the generated
# hardware config in nix/nixos/machines/<machine>/hardware-configuration.nix.
#
# Usage:
#   ./nix/nixos/scripts/install-nixos.sh <target_host> <flake>
# Example:
#   ./nix/nixos/scripts/install-nixos.sh root@1.2.3.4 "$PWD#pinheiro-nuc"
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <target_host> <flake>"
  exit 1
fi

TARGET_HOST="$1"
FLAKE="$2"

if [[ "${FLAKE}" != *"#"* ]]; then
  echo "FLAKE must include a machine target, for example: /path/to/flake#pinheiro-nuc"
  exit 1
fi

FLAKE_PATH="${FLAKE%%#*}"
MACHINE_NAME="${FLAKE#*#}"
if [ -z "${FLAKE_PATH}" ]; then
  FLAKE_PATH="."
fi
if [ -z "${MACHINE_NAME}" ]; then
  echo "FLAKE target is empty. Expected: /path/to/flake#pinheiro-nuc"
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "nix is required but not found in PATH"
  exit 1
fi

FLAKE_ROOT="$(cd "${FLAKE_PATH:-.}" && pwd)"
MACHINE_DIR="${FLAKE_ROOT}/nix/nixos/machines/${MACHINE_NAME}"
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
