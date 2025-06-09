## The docker compose stack
infa provides the shared stuff like reverse proxy and metrics.
All stacks (docker compose files) can be managed with a script. See examples below
```bash
# Usage: manage.sh up|down|restart
./infra/manage.sh up # Starts the infra docker compose stack
# Same goes for `automation`, `lab` and `tedflix`. Infra is needed for the rest to work (f.ex it provides the reverse proxy)
```