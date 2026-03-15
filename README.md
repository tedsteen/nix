# My NIX stuff

Root-flake Nix setup for my Linux and macOS machines.

Depends on the nix package manager: https://nixos.org/download/

## Start here

- Repo layout and conventions: [nix/README.md](./nix/README.md)
- Linux hosts: [nix/nixos/README.md](./nix/nixos/README.md)
- Macs: [nix/darwin/README.md](./nix/darwin/README.md)

## Managing Linux machines

Make sure your target machine is reachable over SSH using `root` or a user with passwordless sudo.

### Bootstrapping a new machine

```bash
./nix/nixos/scripts/install-nixos.sh root@<ip> "$PWD#pinheiro-nuc"
```

### Updating an existing machine

```bash
./nix/nixos/scripts/apply-nixos-config.sh ted@<ip> "./#pinheiro-nuc"
```

## Applying macOS config locally

```bash
sudo ./update_mac.sh
# or: sudo ./update_mac.sh teds-mbp
```
