## First time setup
### Observability
* Grafana LGTM is exposed at http://pinheiro-nuc/grafana
* The host Alloy service collects host metrics, Docker metrics, systemd logs, and Docker logs.
* Host and Docker metrics are scraped as Prometheus metrics and forwarded to otel-lgtm over OTLP/HTTP on `127.0.0.1:14318`.
* Systemd and Docker logs are pushed directly to otel-lgtm's Loki API on `127.0.0.1:13100`, so Loki stream labels stay queryable.
* Docker logs are collected from the Docker socket with Alloy's Docker source. They do not use Docker's `fluentd` logging driver.
* Docker log labels include:
    * `job="integrations/docker"`
    * `service_name="docker/<compose-service-or-container>"`
    * `container`, `stream`, `compose_project`, `compose_service`, `host`, and `instance`
* Systemd logs are collected from journald and labeled with `job="systemd-journal"`, `service_name="systemd-journal"`, `unit`, `syslog_identifier`, `level`, and `host`.
* LGTM data is stored in the `otel-lgtm-data` Docker volume owned by the NixOS `observabilityStack` module.
* Grafana provisions dashboards into the `Observability` folder:
    * Node Exporter Full, fetched from Grafana dashboard `1860` revision `45`
    * Docker monitoring, fetched from Grafana dashboard `15798` revision `13`
    * Home Assistant (Prometheus), maintained locally for Home Assistant's `prometheus:` integration
* Home Assistant's `prometheus:` integration is enabled by the repo-owned automation stack configuration; see `../automation/README.md`.
* Traefik ACME certificates are stored in the `infra_traefik_letsencrypt` Docker volume.
