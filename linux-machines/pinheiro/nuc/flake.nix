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
        (import ../../system-boot-config.nix {
          inherit disko;
          mainDevice = "/dev/sda";
        })
        (import ../../basic-system-config.nix {
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
              infra = {
                path = ./docker/infra;
                backupSchedule = "Mon 03:00 UTC"; # weekly on Mondays at 03:00 UTC
              };

              automation = {
                path = ./docker/automation;
                backupSchedule = "*-*-* 04:00 UTC"; # daily at 04:00 UTC
              };
              
              tedflix = {
                path = ./docker/tedflix;
                backupSchedule = "*-*-* 05:00 UTC"; # daily at 05:00 UTC
              };

              lab = {
                path = ./docker/lab;
                backupSchedule = "Tue 03:00 UTC"; # weekly on Tuesdays at 03:00 UTC
              };
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
              ExecStart = pkgs.writeScript "tedflix-start-on-remount" ''
                #!${pkgs.bash}/bin/bash
                if mountpoint -q /mnt/mediapool; then
                  echo "[+] mediapool mounted, starting the tedflix stack"
                  docker compose -p tedflix start
                fi
              '';
              ExecStop = pkgs.writeScript "tedflix-down-on-unmount" ''
                #!${pkgs.bash}/bin/bash
                echo "[+] mediapool unmounted, stopping the tedflix stack"
                docker compose -p tedflix stop
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

          # NOTE: The yaml-file is encrypted with the auto-imported SSH pinheiro-nuc keys, it is only decryptable by the pinheiro-nuc machine
          #       tl;dr: It was encrypted like this: `sops -e -i secrets.yaml`
          sops = {
            defaultSopsFile = ./secrets.yaml;
            secrets = {
              cloudflare_s3n_io_ddns_api_token = {
                mode = "0440";
                owner = "root";
                group = "docker";
              };
              ntfy_topic = {
                mode = "0440";
                owner = "root";
                group = "docker";
              };
            };
          };

          environment.systemPackages = [
            (pkgs.writeShellScriptBin "ntfy-alert" ''
              set -euo pipefail
              topic=$(<${config.sops.secrets.ntfy_topic.path})
              ${pkgs.curl}/bin/curl -sS -d "$1" "https://ntfy.sh/$topic" > /dev/null
            '')
            # Highjack the sendmail command to use ntfy-alert
            (pkgs.writeShellScriptBin "sendmail" ''
              #!/bin/sh
              /run/current-system/sw/bin/ntfy-alert "SMARTD: $(cat -)"
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
              interval = "monthly";
              pools = [ "mediapool" ];
            };
          };

          services.smartd = {
            enable = true;
            autodetect = false;
            notifications.mail = {
              enable = true;
              sender = "smartd@pinherio.s3n.io";
            };

            devices = builtins.map (i: {
              device = "/dev/disk/by-id/usb-ST18000N_T001-3NF101_2024051400025-0:${toString i}";
              # Short test: every Saturday @ 2AM
              # Long test: every 2nd @ 3AM
              options = "-a -d sat -n standby,10 -s (S/../../6/02|L/../../2/03)";
            }) (builtins.genList (x: x) 5);
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