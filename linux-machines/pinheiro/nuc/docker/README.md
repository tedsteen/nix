## The docker compose stack
infa provides the shared stuff like reverse proxy and metrics.
All stacks (docker compose files) can be managed with a script. See examples below
```bash
# Usage: ./infra up|down|restart
# Same goes for `automation.sh`, `lab.sh` and `tedflix.sh`. Infra is needed for the rest to work (f.ex it provides the reverse proxy)
./infra.sh up # Starts the infra docker compose stack
```