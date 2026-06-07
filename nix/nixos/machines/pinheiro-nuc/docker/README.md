## The docker compose stack
infra provides the shared stuff like the landing page and public Traefik routes. The host NixOS config owns the local observability stack.
Each stack is exposed on the host as zsh aliases for `docker compose`, using a `dcs-` prefix to avoid collisions, including `dcs-<stack>-deploy`.
```bash
dcs-infra-deploy      # Pulls, builds, and deploys the infra stack
dcs-automation ps     # Runs `docker compose ps` for the automation stack
dcs-tedflix down      # Stops and removes the tedflix stack
```

## Declarative boundary
Nix owns the stack definitions copied into `/etc/docker-stacks`, the per-stack environment files, the SOPS-backed secrets referenced by Compose, and the `dcs-*` aliases.

Docker named volumes are application-owned runtime state. Deploying the NixOS config or rerunning `dcs-<stack>-deploy` will not recreate their contents. The main non-declarative volumes are:

* `otel-lgtm-data`: LGTM storage and any Grafana UI changes. Nix provisions the common host and Docker dashboards from pinned upstream revisions, and the Home Assistant dashboard from `infra/grafana/dashboards`.
* `infra_traefik_letsencrypt`: Traefik ACME certificate state.
* `automation_hass_config`: Home Assistant auth, integrations, registries, and UI-managed automations. The top-level `configuration.yaml` and observability package are mounted from the repo.
* `automation_nodered_data`: Node-RED flows, credentials, and settings. Required palettes are installed from the repo-owned Node-RED `package.json`.
* `lab_minecraft_data`: Minecraft world state.
* `tedflix_*`: Tedflix application config and media-app databases. The Tedflix stack is currently documented as a proof of concept.

## Host UPS
The Eaton 3S 550 attached over USB is managed by NUT from the NixOS host config.

Query it on `pinheiro-nuc` with:

```bash
upsc eaton-3s@localhost
```

NUT shuts the host down through systemd when the UPS reports low battery. The configured low-battery threshold is 25%, with a short final delay so shutdown starts promptly.
