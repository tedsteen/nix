{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, home-manager, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix

        (import ../../../linux-system-boot-config.nix {
          inherit disko;
          mainDevice = "/dev/sda";
        })
        
        ../../../hardening-config.nix

        (import ../../../basic-system-config.nix {
          hostName = "pinherio-nuc";
          timeZone = "Europe/Lisbon";
        })

        (import ../../../user-and-shell-config.nix {
          userName = "ted";
          userEmail = "ted.steen@gmail.com";
          userFullName = "Ted Steen";
          userAuthorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
          ];
        })

        home-manager.nixosModules.home-manager

        ({ pkgs, ... }: let
            backupDockerVolumesScript = pkgs.writeScriptBin "docker-volumes-backup"
              (builtins.readFile ./scripts/docker-volumes-backup.sh);
            restoreDockerVolumesScript = pkgs.writeScriptBin "docker-volumes-restore"
              (builtins.readFile ./scripts/docker-volumes-restore.sh);
        in {
          console.keyMap = "dvorak";

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

          # Enable docker
          virtualisation.docker.enable = true;
          # Allow the user "ted" to run docker commands without sudo
          users.users.ted.extraGroups = [ "docker" ];
          home-manager.users.ted = {
            programs.fish.shellAbbrs = nixpkgs.lib.mkBefore {
              # Delete all stopped containers (including data-only containers)
              dkrm="for id in (docker ps -aq -f status=exited); docker rm -f $id; end";
              dkkill="for id in (docker ps -q); docker kill $id; end";
            };
            
            home = {
              packages = [
                backupDockerVolumesScript
                restoreDockerVolumesScript
              ];
            };
          };
          
          # Let docker expose port 80 for traefik (all of the services run on that port)
          boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;
          networking.firewall.allowedTCPPorts = [ 80 ];

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          home-manager.users.ted.home.stateVersion = "24.11";
          system.stateVersion = "24.11";
          
        })
      ];
    };
  };
}