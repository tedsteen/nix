## First time setup
### Observability
* Grafana LGTM is exposed at http://pinheiro-nuc/grafana
* The host OpenTelemetry Collector listens on:
    * OTLP/gRPC: `pinheiro-nuc:4317`
    * OTLP/HTTP: `http://pinheiro-nuc:4318`
* The collector sends host, Docker, application metrics, traces, and logs to the `docker-otel-lgtm` service.
* Systemd logs are read from journald.
* Docker container stdout/stderr logs are sent directly from Docker's `fluentd` logging driver to the host OpenTelemetry Collector's `fluentforward` receiver on `127.0.0.1:24224`. Existing containers need to be recreated before they use the current Docker logging driver.
* Docker logs are labeled in Loki from OpenTelemetry resource attributes:
    * `service_namespace`: Compose project, or `docker` for non-Compose containers
    * `service_name`: Compose service, or container name for non-Compose containers
    * `container_name`: Docker container name
* Docker log structured metadata includes `container_id`, `docker_stream`, `compose_project`, `compose_service`, `compose_container_number`, and `log_source`.
* Systemd logs are labeled with `service_namespace="systemd"` and `service_name` set to the systemd unit, for example `{service_namespace="systemd", service_name="docker.service"}`.
* LGTM data is stored in the `infra_otel_lgtm` Docker volume. Dashboards in this repo are provisioned automatically, but Grafana UI changes are runtime state unless exported back into `./grafana/dashboards`.
* Grafana provisions dashboards from `./grafana/dashboards` into the `Pinheiro` folder:
    * Host Metrics (opentelemetry), imported from Grafana dashboard `24638`
    * Docker Containers (OpenTelemetry), maintained locally for the OTel `docker_stats` receiver
    * Home Assistant (Prometheus), maintained locally for Home Assistant's `prometheus:` integration
* Home Assistant's `prometheus:` integration is enabled by the repo-owned automation stack configuration; see `../automation/README.md`.
* Traefik ACME certificates are stored in the `infra_traefik_letsencrypt` Docker volume.
