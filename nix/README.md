# Nix

Host configuration for this repo: NixOS for Linux machines and nix-darwin for Macs.

## Start Here

- Linux hosts: [nix/nixos/README.md](./nixos/README.md)
- Macs: [nix/darwin/README.md](./darwin/README.md)

## Layout

- `nixos/`: Linux machines, shared modules, and helper scripts
- `darwin/`: macOS machines, shared modules, and helper scripts
- `../shared/`: reusable Home Manager module imported by both OS flakes

## Conventions

For a Linux host:

1. Add `nix/nixos/machines/<machine>/default.nix`.
2. Keep each machine's `hardware-configuration.nix` next to its `default.nix`.
3. Add the `nixosConfigurations` entry in [nixos/flake.nix](./nixos/flake.nix).

For a Mac:

1. Add `nix/darwin/machines/<machine>/default.nix`.
2. Reuse `nix/darwin/modules/` where it helps.
3. Add the `darwinConfigurations` entry in [darwin/flake.nix](./darwin/flake.nix).
