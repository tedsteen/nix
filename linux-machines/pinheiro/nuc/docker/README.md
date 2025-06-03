## The NUC @ Pinheiro
For provisioning see https://github.com/tedsteen/nix

```bash
# To deploy the infa on the nuc with the correct config dir use `/var/nuc` as the path f.ex
# Note: `restart` and `down` is also available.
# Same goes for `automation.sh` and `lab.sh`
./infra.sh up

# TODO: Start the infra docker compose environment on your local docker
# ./infra.sh up local
```