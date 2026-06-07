# NixOS

Linux host definitions and helper scripts.

## Layout

- `modules/`: shared Linux baseline and Docker stack helpers
- `machines/`: machine definitions
- `scripts/`: install and apply helpers

## Common Commands

```bash
./nix/nixos/scripts/install-nixos.sh root@<SERVER_IP> pinheiro-nuc
./nix/nixos/scripts/apply-nixos-config.sh ted@<SERVER_IP> pinheiro-nuc
./nix/nixos/scripts/apply-nixos-config.sh ted@<SERVER_IP> marati-nuc
```

`install-nixos.sh` writes hardware configuration to `nix/nixos/machines/<machine>/hardware-configuration.nix` and uses your normal SSH setup.
