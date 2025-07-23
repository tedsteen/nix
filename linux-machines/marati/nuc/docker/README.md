## The docker compose stack
infa provides the shared stuff like reverse proxy and metrics.
All stacks (docker compose files) can be managed with a script. See examples below
```bash
# Usage: manage.sh up|down|start|stop|restart
./infra/manage.sh up # Starts the infra docker compose stack
```