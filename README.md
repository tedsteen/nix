## Bootstraping
Make sure your target machine is ready with root or user with passwordless sudo. You need the username and password to be able to do the install over SSH.

```bash
export TARGET_HOST="<user>@<ip>"
nix run github:nix-community/nixos-anywhere/1.9.0 -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --flake .#pinheiro --build-on remote $TARGET_HOST --target-host $TARGET_HOST
```
