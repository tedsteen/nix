{ inputs, config, lib, pkgs, ... }:
let
  me = {
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
  tedflixMediaPath = "/mnt/mediapool/tedflix";
  dockerStackComposeCommand = name:
    "${pkgs.docker}/bin/docker compose --env-file /etc/docker-stacks/${name}.env --project-name ${name} -f /etc/docker-stacks/${name}/docker-compose.yaml";
  ntfyAlertCommand = "/run/current-system/sw/bin/ntfy-alert";
  tedflixComposeCommand = dockerStackComposeCommand "tedflix";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../modules/base.nix
    ../../modules/docker-stacks.nix
    ./hardware-configuration.nix
  ];

  nixosBaseConfig.users.ted = me;

  disko.devices.disk.main.device = "/dev/sda";

  networking.hostName = "pinheiro-nuc";

  time.timeZone = "Europe/Lisbon";

  system.stateVersion = "24.11";

  virtualisation.docker.enable = true;

  services.dockerStack = {
    stacks = {
      infra = {
        path = ./docker/infra;
        env = {
          INFRA_WIREGUARD_CONFIG = "/run/secrets/infra_wireguard_config";
        };
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
          TEDFLIX_PATH = tedflixMediaPath;
        };
      };
    };
  };

  systemd.services.docker-health-monitor = {
    description = "Warn me if any Docker container is unhealthy";
    path = [ pkgs.docker ];
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    serviceConfig.Type = "oneshot";

    script = ''
      bad=$(docker ps --filter "health=unhealthy" --format '{{.Names}}')
      if [ -n "$bad" ]; then
        ${ntfyAlertCommand} "Docker unhealthy on pinheiro-nuc:\n\n$bad"
      fi
    '';
  };

  systemd.timers.docker-health-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";       # First run after boot.
      OnUnitActiveSec = "5m"; # Repeat cadence.
      Unit = "docker-health-monitor.service";
      Persistent = true;      # Catch up after downtime.
    };
  };

  # Keep only tedflix tied to the mediapool mount. The other stacks should keep
  # running even if that pool disappears for a while.
  systemd.services.docker-stack-tedflix-guard = {
    description = "Keep tedflix in sync with mediapool mount";
    path = [ pkgs.coreutils pkgs.docker pkgs.gnugrep pkgs.util-linux ];
    wantedBy = [ "mnt-mediapool.mount" ];
    after = [ "docker.service" "mnt-mediapool.mount" ];
    wants = [ "docker.service" "mnt-mediapool.mount" ];
    bindsTo = [ "mnt-mediapool.mount" ];
    partOf = [ "mnt-mediapool.mount" ];
    unitConfig.RequiresMountsFor = [ "/mnt/mediapool" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = pkgs.writeShellScript "tedflix-prepare-media-path" ''
        media_path=${lib.escapeShellArg tedflixMediaPath}

        if [ ! -d "$media_path/downloads/complete" ] \
          || [ ! -d "$media_path/downloads/incomplete" ] \
          || [ ! -d "$media_path/downloads/manual" ] \
          || [ ! -d "$media_path/movies" ] \
          || [ ! -d "$media_path/tv" ]; then
          mkdir -p \
            "$media_path"/downloads/{complete,incomplete,manual} \
            "$media_path"/movies \
            "$media_path"/tv
          chown -R 1000:100 "$media_path"
        fi
      '';
      ExecStart = pkgs.writeShellScript "tedflix-start-on-mount" ''
        echo "[+] mediapool mounted, starting the tedflix stack if it's there"
        if ${tedflixComposeCommand} ps --all -q | grep -q .; then
          ${tedflixComposeCommand} start
        fi
      '';
      ExecStop = pkgs.writeShellScript "tedflix-stop-on-unmount" ''
        if mountpoint -q /mnt/mediapool; then
          echo "[+] mediapool is still mounted, skipping tedflix stop/alert"
          exit 0
        fi

        echo "[+] mediapool unmounted, stopping the tedflix stack"
        ${tedflixComposeCommand} stop
        ${ntfyAlertCommand} "Mediapool was unmounted and tedflix stack was stopped."
      '';
    };
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

  systemd = {
    services.check-failed-units = {
      description = "Alert on failed systemd units";
      path = [ pkgs.systemd ];
      serviceConfig.Type = "oneshot";
      script = ''
        failed=$(systemctl list-units --state=failed --type=service --plain --no-pager --legend=false)
        if [ -n "$failed" ]; then
          ${ntfyAlertCommand} "Failed systemd services on pinheiro-nuc:\n\n$failed"
        fi
      '';
    };

    timers.check-failed-units = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "10min";
        Persistent = true;
      };
    };
  };

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
