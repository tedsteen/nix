{ inputs, config, pkgs, ... }:
let
  ntfyAlertCommand = "/run/current-system/sw/bin/ntfy-alert";
  upsMonitorPasswordFile = "${pkgs.writeText "upsmon-password" "pinheiro-upsmon\n"}";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../modules/base.nix
    ../../modules/docker-stacks.nix
    ../../modules/observability-stack.nix
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
  # Match the official WordPress image's www-data group so Apache can read its mounted secret.
  users.groups.container-www-data.gid = 33;

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

  virtualisation.docker.enable = true;

  systemd.services.docker = {
    after = [ "mnt-mediapool.mount" ];
    wants = [ "mnt-mediapool.mount" ];
  };

  power.ups = {
    enable = true;
    mode = "standalone";
    ups."eaton-3s" = {
      description = "Eaton 3S 550";
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        "vendorid = 0463"
        "productid = ffff"
        "lowbatt = 25"
        "ignorelb"
        "offdelay = 120"
        "ondelay = 180"
      ];
    };
    upsd.listen = [
      { address = "127.0.0.1"; }
    ];
    users.upsmon = {
      passwordFile = upsMonitorPasswordFile;
      upsmon = "primary";
    };
    upsmon = {
      monitor."eaton-3s" = {
        system = "eaton-3s@localhost";
        user = "upsmon";
        type = "primary";
      };
      settings.FINALDELAY = 5;
    };
  };

  services.observabilityStack = {
    enable = true;
    homeAssistant.enable = true;
    extraDashboardPaths = [
      ./docker/infra/grafana/dashboards/home-assistant-prometheus.json
    ];
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
    path = [ config.virtualisation.docker.package ];
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
      moobeldaja_db_password = {
        mode = "0440";
        owner = "ted";
        group = "container-www-data";
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
