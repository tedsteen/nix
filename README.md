# My NIX stuff
Nix flakes for installing some machines and configuring my macs.

Depends on the nix package manager: https://nixos.org/download/

## Managing linux machines
Make sure your target machine is reachable over SSH using root or user with passwordless sudo.

### Bootstrapping a new machine
```bash
./create_machine.sh <user>@<ip> <path_to_linux_machine>
```

### Updating an existing machine
```bash
./update_machine.sh <user>@<ip> <path_to_linux_machine>
```

## Setup my Mac and user
```bash
sudo ./update_mac.sh
```