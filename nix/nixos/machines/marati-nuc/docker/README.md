## The docker compose stack
infra provides the shared stuff like reverse proxy and metrics.
Each stack is exposed on the host as zsh aliases for `docker compose`, using a `dcs-` prefix to avoid collisions, including `dcs-<stack>-deploy`.
```bash
dcs-infra-deploy
dcs-infra ps
```
