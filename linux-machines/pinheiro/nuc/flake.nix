{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, home-manager, sops-nix, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hardware-configuration.nix
        ../../hardening-config.nix
        ./docker/modules/docker-stacks.nix
        (import ../../base-system-config.nix {
          inherit disko;
          mainDevice = "/dev/sda";
          hostName = "pinheiro-nuc";
          timeZone = "Europe/Lisbon";
          username = "ted";
          email = "ted.steen@gmail.com";
          fullName = "Ted Steen";
        })

        ({ config, pkgs, ... }: {
          console.keyMap = "dvorak";
          
          virtualisation.docker.enable = true;
          
          # TODO: Move to hetzner (https://www.hetzner.com/storage/storage-box/)
          environment.etc."restic/docker-stacks.env".text = ''
            RESTIC_REPOSITORY="/backup/docker-stacks"
            RESTIC_PASSWORD="password"
          '';

          services.dockerStack = {
            resticEnvFile = "/etc/restic/docker-stacks.env";
            stacks = {
              # Run all backups on Saturday, from 01:00 CET to 02:30 CET
              infra = {
                path = ./docker/infra;
                backupSchedule = "Sat 01:00 CET";
              };

              automation = {
                path = ./docker/automation;
                backupSchedule = "Sat 01:30 CET";
              };

              lab = {
                path = ./docker/lab;
                backupSchedule = "Sat 02:00 CET";
              };

              tedflix = {
                path = ./docker/tedflix;
                backupSchedule = "Sat 02:30 CET";
              };
            };
          };

          systemd.services.docker-health-monitor = {
            description = "Warn me if any Docker container is unhealthy";
            path = [ pkgs.docker ];
            after = [ "docker.service" ];
            wants = [ "docker.service" ];
            serviceConfig = {
              Type = "oneshot";
            };

            script = ''
              bad=$(docker ps --filter "health=unhealthy" --format '{{.Names}}')
              if [ -n "$bad" ]; then
                /run/current-system/sw/bin/ntfy-alert "Docker unhealthy:\n\n$bad"
              fi
            '';
          };

        systemd.timers.docker-health-monitor = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5m";         # first run after boot
            OnUnitActiveSec = "5m";   # repeat cadence
            Unit = "docker-health-monitor.service";
            Persistent = true;        # catch-up after suspend
          };
        };

          systemd.services.docker-stack-tedflix-guard = {
            description = "Keep tedflix in sync with mediapool mount";
            path = [ pkgs.bash pkgs.docker pkgs.util-linux ];
            wantedBy = [ "multi-user.target" "mnt-mediapool.mount" ];
            after = [ "docker.service" "mnt-mediapool.mount" ];
            wants = [ "docker.service" "mnt-mediapool.mount" ];
            unitConfig = {
              BindsTo = [ "mnt-mediapool.mount" ]; # service stops if mount goes away
              RequiresMountsFor = [ "/mnt/mediapool" ];
            };
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = pkgs.writeScript "tedflix-start-on-mount" ''
                #!${pkgs.bash}/bin/bash
                if mountpoint -q /mnt/mediapool; then
                  echo "[+] mediapool mounted, starting the tedflix stack if it's there"
                  if docker compose -p tedflix ps --all -q | grep -q .; then
                      docker compose -p tedflix start
                  fi
                fi
              '';
              ExecStop = pkgs.writeScript "tedflix-stop-on-unmount" ''
                #!${pkgs.bash}/bin/bash
                echo "[+] mediapool unmounted, stopping the tedflix stack"
                docker compose -p tedflix stop
                /run/current-system/sw/bin/ntfy-alert "Mediapool was unmounted and tedflix stack was stopped."
              '';
            };
          };

          users.users.ted = {
            isNormalUser = true;
            shell = pkgs.zsh;
            # Sudo and docker access for ted
            extraGroups = [ "wheel" "docker" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
            ];
          };
          
          home-manager.users."ted" = {
            # The state versions are required and should stay at the version you
            # originally installed.
            # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
            home.stateVersion = "24.11";
          };

          # Lock down root and password access but let the user "ted" in with private key and enable passwordless sudo
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              ChallengeResponseAuthentication = false;
              PermitRootLogin = "no";
              PubkeyAuthentication = true;
            };
          };
          security.sudo.extraRules = [
            {
              users = [ "ted" ];
              commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
            }
          ];

          sops = {
            # Encrypted with `sops -e -i secrets.yaml`, see `.sops.yaml` for recipients.
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

          environment.systemPackages = [
            (pkgs.writeShellScriptBin "ntfy-alert" ''
              #!/bin/sh
              set -euo pipefail
              topic=$(<${config.sops.secrets.ntfy_topic.path})
              ${pkgs.curl}/bin/curl -sS -d "$(printf '%b' "$1")" "https://ntfy.sh/$topic" > /dev/null
            '')
            # Highjack the sendmail command to use ntfy-alert
            (pkgs.writeShellScriptBin "sendmail" ''
              #!/bin/sh
              /run/current-system/sw/bin/ntfy-alert "$(cat -)"
            '')
            # smartd-specific wrapper that picks up $SMARTD_MESSAGE
            (pkgs.writeShellScriptBin "ntfy-smartd" ''
              #!/bin/sh
              set -euo pipefail
              /run/current-system/sw/bin/ntfy-alert "SMARTD: ''${SMARTD_MESSAGE:-unknown}"
            '')
          ];
          
          systemd = {
            services.check-failed-units = {
              description = "Alert on failed systemd units";
              serviceConfig = {
                Type = "oneshot";
              };
              script = ''
                failed=$(systemctl --failed --no-legend)
                if [ -n "$failed" ]; then
                  /run/current-system/sw/bin/ntfy-alert "Failed systemd units on pinheiro-nuc:\n\n$failed"
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
                "-a " +                                 # Monitor everything
                "-d sat " +                             # SAT layer
                "-s (S/../../7/02|L/../01-07/1/01) " +  # Short - Sun @ 01:00. Long - first Monday of the month @ 01:00
                "-m <nomail> " +                        # *Dummy* mail target (required)
                "-M exec /run/current-system/sw/bin/ntfy-smartd";
            }) (builtins.genList (x: x) 5);
          };

          # ZFS stuff
          boot = {
            kernelModules = [ "zfs" ];
            supportedFilesystems = [ "zfs" ];
          };

          networking.hostId = "1f666b7f"; # head -c4 /dev/urandom | od -A none -t x4
          services.zfs = {
            zed = {
              settings = {
                ZED_DEBUG_LOG = "/var/log/zed.log";
                ZED_EMAIL_ADDR = [ "root" ];
                ZED_EMAIL_PROG = "/run/current-system/sw/bin/sendmail"; # Use the highjacked sendmail command
                ZED_NOTIFY_INTERVAL_SECS = "3600";
                ZED_LOG_EXECS = "YES";
                ZED_SYSLOG_PRIORITY = "daemon.info";
              };
            };

            autoScrub = {
              enable = true;
              interval = "Mon *-*-08..14 01:00"; # 2nd Monday of the month @ 01:00
              pools = [ "mediapool" ];
            };
          };

          fileSystems."/mnt/mediapool" = {
            # NOTE: If the pool is degraded it might take a long time to import it (see https://github.com/NixOS/nixpkgs/issues/413060)
            device = "mediapool";
            fsType = "zfs";
            options = [ "nofail" ]; # We want to be able to boot even tho there is no mediapool
          };

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = "24.11";
        })
      ];
    };
  };
}