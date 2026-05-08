{ inputs, config, pkgs, ... }:
let
  ntfyAlertCommand = "/run/current-system/sw/bin/ntfy-alert";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../modules/base.nix
    ../../modules/docker-stacks.nix
    ./hardware-configuration.nix
  ];

  nixosBaseConfig.users.ted = {
    fullName = "Ted Steen";
    email = "ted.steen@gmail.com";
    homeStateVersion = "24.11";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
    ];
    extraGroups = [ "docker" ];
    sudoNoPassword = true;
  };

  disko.devices.disk.main.device = "/dev/sda";

  networking.hostName = "pinheiro-nuc";

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
    extraSetFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
  };
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  # Improve UDP forwarding throughput for the Tailscale exit node.
  systemd.services.tailscale-udp-gro = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "tailscale-udp-gro" ''
        set -eu

        iface="$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk '/default/ { print $5; exit }')"
        [ -n "$iface" ] || exit 0

        ${pkgs.ethtool}/bin/ethtool -K "$iface" rx-udp-gro-forwarding on rx-gro-list off || {
          echo "tailscale-udp-gro: skipping optional GRO tuning for interface $iface" >&2
          exit 0
        }
      '';
    };
  };
  time.timeZone = "Europe/Lisbon";

  system.stateVersion = "24.11";

  virtualisation.docker = {
    enable = true;
    daemon.settings."log-driver" = "journald";
  };

  systemd.services.docker = {
    after = [ "mnt-mediapool.mount" ];
    wants = [ "mnt-mediapool.mount" ];
  };

  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.opentelemetry-collector-contrib;
    validateConfigFile = true;
    settings = {
      extensions = {
        health_check.endpoint = "127.0.0.1:13133";
        "file_storage/journald".directory = ".";
      };

      receivers = {
        otlp.protocols = {
          grpc.endpoint = "0.0.0.0:4317";
          http.endpoint = "0.0.0.0:4318";
        };

        hostmetrics = {
          collection_interval = "30s";
          scrapers = {
            cpu.metrics."system.cpu.utilization".enabled = true;
            disk = { };
            filesystem = {
              exclude_mount_points = {
                match_type = "regexp";
                mount_points = [
                  "^/dev($|/.*)"
                  "^/proc($|/.*)"
                  "^/run($|/.*)"
                  "^/sys($|/.*)"
                  "^/var/lib/docker($|/.*)"
                ];
              };
              exclude_fs_types = {
                match_type = "strict";
                fs_types = [
                  "autofs"
                  "binfmt_misc"
                  "bpf"
                  "cgroup2"
                  "configfs"
                  "debugfs"
                  "devpts"
                  "devtmpfs"
                  "fusectl"
                  "hugetlbfs"
                  "iso9660"
                  "mqueue"
                  "nsfs"
                  "overlay"
                  "proc"
                  "procfs"
                  "pstore"
                  "rpc_pipefs"
                  "securityfs"
                  "selinuxfs"
                  "squashfs"
                  "sysfs"
                  "tracefs"
                ];
              };
              metrics."system.filesystem.utilization".enabled = true;
            };
            load = { };
            memory.metrics."system.memory.utilization".enabled = true;
            network = { };
            paging = { };
            processes = { };
          };
        };

        docker_stats = {
          collection_interval = "30s";
          endpoint = "unix:///var/run/docker.sock";
          container_labels_to_metric_labels = {
            "com.docker.compose.project" = "docker.compose.project";
            "com.docker.compose.service" = "docker.compose.service";
          };
        };

        journald = {
          all = true;
          directory = "/var/log/journal";
          storage = "file_storage/journald";
        };

        "prometheus/home_assistant".config.scrape_configs = [
          {
            job_name = "home-assistant";
            scrape_interval = "60s";
            metrics_path = "/api/prometheus";
            static_configs = [
              { targets = [ "127.0.0.1:18123" ]; }
            ];
          }
        ];
      };

      processors = {
        batch = { };
        "resource/home-assistant".attributes = [
          {
            key = "service.namespace";
            value = "pinheiro";
            action = "upsert";
          }
          {
            key = "service.name";
            value = "home-assistant";
            action = "upsert";
          }
          {
            key = "host.name";
            value = "pinheiro-nuc";
            action = "upsert";
          }
        ];
        "resource/pinheiro-nuc".attributes = [
          {
            key = "service.namespace";
            value = "pinheiro";
            action = "upsert";
          }
          {
            key = "service.name";
            value = "pinheiro-nuc";
            action = "upsert";
          }
          {
            key = "host.name";
            value = "pinheiro-nuc";
            action = "upsert";
          }
        ];
        "transform/journald" = {
          error_mode = "ignore";
          log_statements = [
            ''set(log.attributes["container.id"], log.body["CONTAINER_ID_FULL"]) where IsMap(log.body) and log.body["CONTAINER_ID_FULL"] != nil''
            ''set(log.attributes["container.image.name"], log.body["IMAGE_NAME"]) where IsMap(log.body) and log.body["IMAGE_NAME"] != nil''
            ''set(log.attributes["container.name"], log.body["CONTAINER_NAME"]) where IsMap(log.body) and log.body["CONTAINER_NAME"] != nil''
            ''set(log.attributes["journal.priority"], log.body["PRIORITY"]) where IsMap(log.body) and log.body["PRIORITY"] != nil''
            ''set(log.attributes["systemd.unit"], log.body["_SYSTEMD_UNIT"]) where IsMap(log.body) and log.body["_SYSTEMD_UNIT"] != nil''
            ''set(log.attributes["syslog.identifier"], log.body["SYSLOG_IDENTIFIER"]) where IsMap(log.body) and log.body["SYSLOG_IDENTIFIER"] != nil''
            ''set(log.body, log.body["MESSAGE"]) where IsMap(log.body) and log.body["MESSAGE"] != nil''
            ''set(log.body, Concat([log.attributes["container.name"], log.body], " | ")) where log.attributes["container.name"] != nil''
          ];
        };
      };

      exporters."otlphttp/lgtm".endpoint = "http://127.0.0.1:14318";

      service = {
        extensions = [
          "health_check"
          "file_storage/journald"
        ];
        pipelines = {
          traces = {
            receivers = [ "otlp" ];
            processors = [ "batch" ];
            exporters = [ "otlphttp/lgtm" ];
          };
          metrics = {
            receivers = [ "otlp" ];
            processors = [ "batch" ];
            exporters = [ "otlphttp/lgtm" ];
          };
          "metrics/host" = {
            receivers = [
              "hostmetrics"
              "docker_stats"
            ];
            processors = [
              "resource/pinheiro-nuc"
              "batch"
            ];
            exporters = [ "otlphttp/lgtm" ];
          };
          "metrics/home-assistant" = {
            receivers = [ "prometheus/home_assistant" ];
            processors = [
              "resource/home-assistant"
              "batch"
            ];
            exporters = [ "otlphttp/lgtm" ];
          };
          logs = {
            receivers = [
              "otlp"
              "journald"
            ];
            processors = [
              "resource/pinheiro-nuc"
              "transform/journald"
              "batch"
            ];
            exporters = [ "otlphttp/lgtm" ];
          };
        };
      };
    };
  };

  systemd.services.opentelemetry-collector = {
    after = [ "docker.service" ];
    path = [ pkgs.systemd ];
    wants = [ "docker.service" ];
    serviceConfig.SupplementaryGroups = [ "docker" ];
  };

  services.dockerStack = {
    stacks = {
      infra = {
        path = ./docker/infra;
      };

      automation = {
        path = ./docker/automation;
      };

      lab = {
        path = ./docker/lab;
      };

      tedflix = {
        path = ./docker/tedflix;
        env = {
          TEDFLIX_PATH = "/mnt/mediapool/tedflix";
          WIREGUARD_CONFIG = "/run/secrets/infra_wireguard_config";
        };
      };
    };
  };

  systemd.services.docker-health-monitor = {
    description = "Alert when a Docker container becomes unhealthy";
    path = [ pkgs.docker ];
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
    };
    script = ''
      docker events --filter 'event=health_status' --format '{{.Actor.Attributes.name}}|{{.Action}}' | \
        while IFS='|' read -r name action; do
          case "$action" in
            *unhealthy*) ${ntfyAlertCommand} "Docker container unhealthy on pinheiro-nuc: $name" ;;
            *healthy*)   ${ntfyAlertCommand} "Docker container healthy again on pinheiro-nuc: $name" ;;
          esac
        done
    '';
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      cloudflare_s3n_io_ddns_api_token = {
        mode = "0440";
        owner = "ted";
        group = "docker";
      };
      ntfy_topic = {
        mode = "0440";
        owner = "ted";
        group = "docker";
      };
      infra_wireguard_config = {
        mode = "0440";
        owner = "ted";
        group = "docker";
      };
      tailscale_auth_key = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };

  # ZED is mail-oriented, so point the system sendmail wrapper at ntfy.
  services.mail.sendmailSetuidWrapper = {
    program = "sendmail";
    source = pkgs.writeShellScript "sendmail-via-ntfy" ''
      exec ${ntfyAlertCommand} "$(cat -)"
    '';
    owner = "root";
    group = "root";
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "ntfy-alert" ''
      #!/bin/sh
      set -euo pipefail
      topic=$(<${config.sops.secrets.ntfy_topic.path})
      ${pkgs.curl}/bin/curl -sS -d "$(printf '%b' "$1")" "https://ntfy.sh/$topic" > /dev/null
    '')
    # smartd-specific wrapper that picks up $SMARTD_MESSAGE.
    (pkgs.writeShellScriptBin "ntfy-smartd" ''
      #!/bin/sh
      set -euo pipefail
      ${ntfyAlertCommand} "SMARTD:\n''${SMARTD_MESSAGE:-unknown}"
    '')
  ];

  services.smartd = {
    enable = true;
    autodetect = false;
    devices = builtins.map (i: {
      device = "/dev/disk/by-id/usb-ST18000N_T001-3NF101_2024051400025-0:${toString i}";
      options =
        "-a " +                                 # Monitor everything.
        "-d sat " +                             # SAT layer.
        "-s (S/../../7/02|L/../01-07/1/01) " +  # Short: Sun @ 02:00. Long: first Monday of the month @ 01:00.
        "-m <nomail> " +                        # Dummy mail target, still required by smartd.
        "-M exec /run/current-system/sw/bin/ntfy-smartd";
    }) (builtins.genList (x: x) 5);
  };

  # ZFS support for the media pool.
  boot = {
    kernelModules = [ "zfs" ];
    supportedFilesystems = [ "zfs" ];
  };

  networking.hostId = "1f666b7f";

  services.zfs = {
    zed.enableMail = true;
    zed.settings = {
      ZED_DEBUG_LOG = "/var/log/zed.log";
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_NOTIFY_INTERVAL_SECS = "3600";
      ZED_LOG_EXECS = "YES";
      ZED_SYSLOG_PRIORITY = "daemon.info";
    };

    autoScrub = {
      enable = true;
      interval = "Mon *-*-08..14 01:00";
      pools = [ "mediapool" ];
    };
  };

  fileSystems."/mnt/mediapool" = {
    device = "mediapool";
    fsType = "zfs";
    # Boot should still succeed even if the pool is temporarily unavailable.
    options = [ "nofail" ];
  };
}
