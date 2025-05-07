## Bootstraping
Make sure your target machine is ready with root or user with passwordless sudo. You need the username and password to be able to do the install over SSH.

```bash
./create_machine.sh <ip> <user> <machine> <config>
```

## Applying new config to existing machine

```bash
./update_machine.sh <ip> <user> <machine> <config>
```