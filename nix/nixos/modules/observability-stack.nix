{ config, lib, pkgs, ... }:

let
  cfg = config.services.observabilityStack;
  lgtmImage = "grafana/otel-lgtm:0.28.0";
  pinPrometheus = ''
    def pin($ds):
      walk(
        if type == "object" and has("datasource") then
          ( if (.datasource | type) == "string" and (.datasource | startswith("$"))
            then .datasource = $ds
            elif (.datasource | type) == "object" and (.datasource.type? == "prometheus")
            then .datasource = $ds
            else . end )
        else . end );
  '';
  fetchDashboard = { name, id, revision, hash, transform }:
    let
      raw = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/${toString id}/revisions/${toString revision}/download";
        inherit hash;
        name = "grafana-dashboard-${toString id}-rev${toString revision}.json";
      };
      jq = pkgs.writeText "${name}-transform.jq" transform;
    in
    pkgs.runCommand "dashboard-${name}" { nativeBuildInputs = [ pkgs.jq ]; } ''
      mkdir -p "$out"
      jq -f ${jq} ${raw} > "$out/${name}.json"
    '';
  commonDashboards = [
    (fetchDashboard {
      name = "node-exporter-full";
      id = 1860;
      revision = 45;
      hash = "sha256-GExrdAnzBtp1Ul13cvcZRbEM6iOtFrXXjEaY6g6lGYY=";
      transform = pinPrometheus + ''
        def scopejob($q):
          .templating.list |= map(
            if .name == "job" then
              .definition = $q
              | .query = (if (.query | type) == "object" then .query + {query: $q} else $q end)
            else . end );

        del(.__inputs)
        | del(.__requires)
        | pin({type: "prometheus", uid: "prometheus"})
        | scopejob("label_values(node_uname_info{job=\"integrations/node_exporter\"}, job)")
      '';
    })
    (fetchDashboard {
      name = "docker-monitoring";
      id = 15798;
      revision = 13;
      hash = "sha256-Lt2X+HTANLKX76gzYUlG6i4DScCDmi7e6RMnPeBsKnw=";
      transform = pinPrometheus + ''
        def variable_query($name; $q):
          .templating.list |= map(
            if .name == $name then
              .definition = $q
              | .query = (if (.query | type) == "object" then .query + {query: $q} else $q end)
            else . end );

        del(.__inputs)
        | del(.__requires)
        | del(.__elements)
        | pin({type: "prometheus", uid: "prometheus"})
        | variable_query("job"; "label_values(container_memory_usage_bytes{job=\"integrations/cadvisor\", image!=\"\"}, job)")
        | variable_query("service"; "label_values(container_memory_usage_bytes{job=~\"$job\", image!=\"\"}, service)")
        | variable_query("node"; "label_values(container_memory_usage_bytes{job=~\"$job\", image!=\"\", service=~\"$service\"}, instance)")
        | variable_query("container"; "label_values(container_memory_usage_bytes{job=~\"$job\", image!=\"\", service=~\"$service\", instance=~\"$node\"}, container)")
      '';
    })
  ];
  dashboardsDir = pkgs.runCommand "observability-dashboards" { } ''
    mkdir -p "$out"
    ${lib.concatMapStrings (dashboard: ''
      cp ${dashboard}/*.json "$out"/
    '') commonDashboards}
    ${lib.concatMapStrings (dashboard: ''
      cp ${dashboard} "$out"/
    '') cfg.extraDashboardPaths}
  '';
  dashboardProvider = pkgs.writeText "observability-dashboards.yaml" ''
    apiVersion: 1

    providers:
      - name: Observability
        orgId: 1
        folder: Observability
        type: file
        disableDeletion: false
        updateIntervalSeconds: 30
        allowUiUpdates: false
        options:
          path: /otel-lgtm/observability-dashboards
          foldersFromFilesStructure: false
  '';
  homeDashboard = pkgs.writeText "observability-home.json" (builtins.toJSON {
    uid = "observability-home";
    title = "Home";
    editable = false;
    schemaVersion = 39;
    version = 1;
    panels = [
      {
        type = "text";
        gridPos = { h = 5; w = 24; x = 0; y = 0; };
        options = {
          mode = "markdown";
          content = "# ${config.networking.hostName}\n\nLocal observability instance.";
        };
      }
    ];
  });
  homeAssistantScrape = lib.optionalString cfg.homeAssistant.enable ''
    prometheus.scrape "home_assistant" {
      targets = [
        {
          "__address__" = "${cfg.homeAssistant.target}",
        },
      ]
      metrics_path     = "${cfg.homeAssistant.metricsPath}"
      scrape_interval = "${cfg.homeAssistant.scrapeInterval}"
      forward_to      = [otelcol.receiver.prometheus.local.receiver]
    }
  '';
in
{
  options.services.observabilityStack = {
    enable = lib.mkEnableOption "local Alloy and otel-lgtm observability stack";

    dataVolumeName = lib.mkOption {
      type = lib.types.str;
      default = "otel-lgtm-data";
      description = "Docker volume used for otel-lgtm data.";
    };

    grafanaPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Host port for Grafana.";
    };

    otlpHttpPort = lib.mkOption {
      type = lib.types.port;
      default = 14318;
      description = "Loopback host port for otel-lgtm's OTLP HTTP endpoint.";
    };

    lokiPort = lib.mkOption {
      type = lib.types.port;
      default = 13100;
      description = "Loopback host port for otel-lgtm's Loki push endpoint.";
    };

    extraDashboardPaths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Additional JSON dashboard files to provision.";
    };

    homeAssistant = {
      enable = lib.mkEnableOption "scraping Home Assistant Prometheus metrics";

      target = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:18123";
        description = "Home Assistant Prometheus scrape target.";
      };

      metricsPath = lib.mkOption {
        type = lib.types.str;
        default = "/api/prometheus";
        description = "Home Assistant Prometheus metrics path.";
      };

      scrapeInterval = lib.mkOption {
        type = lib.types.str;
        default = "60s";
        description = "Home Assistant scrape interval.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = lib.mkDefault true;
    virtualisation.oci-containers = {
      backend = "docker";
      containers.otel-lgtm = {
        image = lgtmImage;
        environment = {
          TZ = config.time.timeZone;
          GF_AUTH_DISABLE_LOGIN_FORM = "true";
          GF_AUTH_ANONYMOUS_ENABLED = "true";
          GF_AUTH_ANONYMOUS_ORG_ROLE = "Admin";
          GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH = "/otel-lgtm/observability-home/home.json";
          GF_SECURITY_ALLOW_EMBEDDING = "true";
        };
        ports = [
          "${toString cfg.grafanaPort}:3000"
          "127.0.0.1:${toString cfg.otlpHttpPort}:4318"
          "127.0.0.1:${toString cfg.lokiPort}:3100"
        ];
        volumes = [
          "${cfg.dataVolumeName}:/data"
          "${dashboardsDir}:/otel-lgtm/observability-dashboards:ro"
          "${dashboardProvider}:/otel-lgtm/grafana/conf/provisioning/dashboards/observability.yaml:ro"
          "${homeDashboard}:/otel-lgtm/observability-home/home.json:ro"
        ];
      };
    };

    services.alloy = {
      enable = true;
      configPath = "/etc/alloy";
    };

    environment.etc."alloy/otel.alloy".text = ''
      otelcol.receiver.prometheus "local" {
        output {
          metrics = [otelcol.processor.batch.local.input]
        }
      }

      otelcol.processor.batch "local" {
        output {
          metrics = [otelcol.exporter.otlphttp.local.input]
        }
      }

      otelcol.exporter.otlphttp "local" {
        client {
          endpoint = "http://127.0.0.1:${toString cfg.otlpHttpPort}"
        }
      }
    '';

    environment.etc."alloy/metrics.alloy".text = ''
      prometheus.exporter.unix "host" { }

      discovery.relabel "host_metrics" {
        targets = prometheus.exporter.unix.host.targets

        rule {
          target_label = "job"
          replacement  = "integrations/node_exporter"
        }

        rule {
          target_label = "host"
          replacement  = constants.hostname
        }

        rule {
          target_label = "instance"
          replacement  = constants.hostname
        }
      }

      prometheus.scrape "host_metrics" {
        targets         = discovery.relabel.host_metrics.output
        scrape_interval = "60s"
        forward_to      = [otelcol.receiver.prometheus.local.receiver]
      }

      prometheus.exporter.cadvisor "docker" {
        docker_only                = true
        store_container_labels     = false
        allowlisted_container_labels = [
          "com.docker.compose.service",
          "com.docker.swarm.service.name",
        ]
      }

      discovery.relabel "docker_metrics" {
        targets = prometheus.exporter.cadvisor.docker.targets

        rule {
          target_label = "job"
          replacement  = "integrations/cadvisor"
        }

        rule {
          target_label = "host"
          replacement  = constants.hostname
        }

        rule {
          target_label = "instance"
          replacement  = constants.hostname
        }
      }

      prometheus.scrape "docker_metrics" {
        targets         = discovery.relabel.docker_metrics.output
        scrape_interval = "60s"
        forward_to      = [prometheus.relabel.docker_metrics.receiver]
      }

      prometheus.relabel "docker_metrics" {
        forward_to = [otelcol.receiver.prometheus.local.receiver]

        rule {
          source_labels = ["name"]
          regex         = "(.+)"
          target_label  = "container"
        }

        rule {
          source_labels = ["name"]
          regex         = "(.+)"
          target_label  = "service"
        }

        rule {
          source_labels = ["container_label_com_docker_compose_service"]
          regex         = "(.+)"
          target_label  = "service"
        }

        rule {
          source_labels = ["container_label_com_docker_swarm_service_name"]
          regex         = "(.+)"
          target_label  = "service"
        }
      }

      ${homeAssistantScrape}
    '';

    environment.etc."alloy/logs.alloy".text = ''
      discovery.relabel "host_journal" {
        targets = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }

        rule {
          source_labels = ["__journal_syslog_identifier"]
          target_label  = "syslog_identifier"
        }

        rule {
          source_labels = ["__journal_container_name"]
          regex         = ".+"
          action        = "drop"
        }

        rule {
          source_labels = ["__journal_priority"]
          regex         = "^[012]$"
          target_label  = "level"
          replacement   = "critical"
        }
        rule {
          source_labels = ["__journal_priority"]
          regex         = "^3$"
          target_label  = "level"
          replacement   = "error"
        }
        rule {
          source_labels = ["__journal_priority"]
          regex         = "^4$"
          target_label  = "level"
          replacement   = "warning"
        }
        rule {
          source_labels = ["__journal_priority"]
          regex         = "^[56]$"
          target_label  = "level"
          replacement   = "info"
        }
        rule {
          source_labels = ["__journal_priority"]
          regex         = "^7$"
          target_label  = "level"
          replacement   = "debug"
        }
      }

      loki.source.journal "host_journal" {
        forward_to    = [loki.write.local.receiver]
        relabel_rules = discovery.relabel.host_journal.rules

        labels = {
          job          = "systemd-journal",
          host         = constants.hostname,
          service_name = "systemd-journal",
        }
      }

      discovery.docker "docker_logs" {
        host             = "unix:///var/run/docker.sock"
        refresh_interval = "5s"
      }

      discovery.relabel "docker_logs" {
        targets = []

        rule {
          target_label = "job"
          replacement  = "integrations/docker"
        }

        rule {
          target_label = "host"
          replacement  = constants.hostname
        }

        rule {
          target_label = "instance"
          replacement  = constants.hostname
        }

        rule {
          source_labels = ["__meta_docker_container_name"]
          regex         = "/(.*)"
          target_label  = "container"
        }

        rule {
          source_labels = ["__meta_docker_container_log_stream"]
          target_label  = "stream"
        }

        rule {
          source_labels = ["__meta_docker_container_label_com_docker_compose_project"]
          target_label  = "compose_project"
        }

        rule {
          source_labels = ["__meta_docker_container_label_com_docker_compose_service"]
          target_label  = "compose_service"
        }

        rule {
          source_labels = ["__meta_docker_container_name"]
          regex         = "/(.*)"
          target_label  = "service_name"
          replacement   = "docker/$1"
        }

        rule {
          source_labels = ["__meta_docker_container_label_com_docker_compose_service"]
          regex         = "(.+)"
          target_label  = "service_name"
          replacement   = "docker/$1"
        }
      }

      loki.process "docker_logs" {
        forward_to = [loki.write.local.receiver]

        stage.match {
          selector = "{stream=\"stdout\"}"

          stage.static_labels {
            values = {
              level = "info",
            }
          }
        }

        stage.match {
          selector = "{stream=\"stderr\"}"

          stage.static_labels {
            values = {
              level = "error",
            }
          }
        }
      }

      loki.source.docker "docker_logs" {
        host             = "unix:///var/run/docker.sock"
        targets          = discovery.docker.docker_logs.targets
        forward_to       = [loki.process.docker_logs.receiver]
        relabel_rules    = discovery.relabel.docker_logs.rules
        refresh_interval = "5s"
      }

      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:${toString cfg.lokiPort}/loki/api/v1/push"
        }
      }
    '';

    systemd.services.alloy = {
      after = [
        "network-online.target"
        "docker.service"
        "docker-otel-lgtm.service"
      ];
      wants = [
        "network-online.target"
        "docker.service"
        "docker-otel-lgtm.service"
      ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        SupplementaryGroups = lib.mkForce [
          "docker"
          "systemd-journal"
        ];
      };
    };
  };
}
