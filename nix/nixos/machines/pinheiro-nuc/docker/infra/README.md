## First time setup
### Observability
* Grafana LGTM is exposed at http://pinheiro-nuc/grafana
* The host OpenTelemetry Collector listens on:
    * OTLP/gRPC: `pinheiro-nuc:4317`
    * OTLP/HTTP: `http://pinheiro-nuc:4318`
* The collector sends host, Docker, application metrics, traces, and logs to the `docker-otel-lgtm` service.
* Systemd and Docker logs are collected from journald and sent to LGTM/Loki. Docker uses the `journald` logging driver, so existing containers need to be recreated before their stdout/stderr logs move into the journal.
* LGTM data is stored in the `infra_otel_lgtm` Docker volume. Dashboards in this repo are provisioned automatically, but Grafana UI changes are runtime state unless exported back into `./grafana/dashboards`.
* Grafana provisions dashboards from `./grafana/dashboards` into the `Pinheiro` folder:
    * Host Metrics (opentelemetry), imported from Grafana dashboard `24638`
    * Docker Containers (OpenTelemetry), maintained locally for the OTel `docker_stats` receiver
    * Home Assistant (Prometheus), maintained locally for Home Assistant's `prometheus:` integration
* Home Assistant's `prometheus:` integration is enabled by the repo-owned automation stack configuration; see `../automation/README.md`.
* Traefik ACME certificates are stored in the `infra_traefik_letsencrypt` Docker volume.
