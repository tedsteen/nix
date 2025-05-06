## Bootstraping
Make sure your target machine is ready with root or user with passwordless sudo. You need the username and password to be able to do the install over SSH.

```bash
./setup_machine.sh <machine> <username> <ip>
```

## Applying new config to existing machine

```bash
export TARGET_HOST="<user>@<ip>"
export TARGET_CONFIG="pinheiro"
nixos-rebuild switch --flake .#$TARGET_CONFIG --target-host $TARGET_HOST
```