## Bootstraping
To bootstrap a new nixOS machine, start the nixOS installer and run this.  
NOTE: Make sure to set the hostname and timezone properly

```bash
nix-shell -p curl --run 'curl -sL https://tinyurl.com/bootstrapnixos | sh -s -- myhostname Europe/Lisbon'
```
