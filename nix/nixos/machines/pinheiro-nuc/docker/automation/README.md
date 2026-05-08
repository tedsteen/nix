## First time setup
### Home Assistant
* Home Assistant is exposed directly on the host at `http://pinheiro-nuc/home-assistant` (redirects to `:18123`)
* Send application telemetry to the host OpenTelemetry Collector at `http://pinheiro-nuc:4318` for OTLP/HTTP or `pinheiro-nuc:4317` for OTLP/gRPC.
* Home Assistant exposes Prometheus metrics at `/api/prometheus`; the host OpenTelemetry Collector scrapes them and forwards them to Grafana LGTM.
* Home Assistant's `configuration.yaml` and the Prometheus integration package are mounted from this repo. The rest of `/config` still lives in the `automation_hass_config` Docker volume, including auth, integrations, registries, and UI-managed automations.
* `requires_auth: false` lets the host collector scrape without a Home Assistant token. The endpoint is intended for the local network only.

### Node Red
* Node-RED's `/data` directory lives in the `automation_nodered_data` Docker volume. Flows, credentials, and settings are runtime state unless exported separately.
* The `node-red-contrib-home-assistant-websocket` palette is installed from the repo-owned Node-RED `package.json`.
* Follow [this guide](https://zachowj.github.io/node-red-contrib-home-assistant-websocket/guide/#configuration) to connect Node Red with HASS
    * Home assistant base URL: `http://home-assistant:8123`
