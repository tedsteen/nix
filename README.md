## Bootstraping
Make sure your target machine is ready with root or user with passwordless sudo. You need the username and password to be able to do the install over SSH.

```bash
./setup_machine.sh <machine> <username> <ip>
```

## Applying new config to existing machine

```bash
./update_machine.sh <machine> <username> <ip>
```