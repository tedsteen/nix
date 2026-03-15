## The docker compose stack
infra provides the shared stuff like reverse proxy and metrics.
Each stack is exposed on the host as zsh aliases for `docker compose`, using a `dcs-` prefix to avoid collisions, including `dcs-<stack>-deploy`.
```bash
dcs-infra-deploy      # Pulls, builds, and deploys the infra stack
dcs-automation ps     # Runs `docker compose ps` for the automation stack
dcs-tedflix down      # Stops and removes the tedflix stack
```
