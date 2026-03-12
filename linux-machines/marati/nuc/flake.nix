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

    userbase = {
      url = "../../../shared";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, disko, home-manager, sops-nix, userbase, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      modules = [
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        userbase.homeManagerModules.userbase
        ./hardware-configuration.nix
        ./modules/docker-stacks.nix
        ../../hardening-config.nix
        
        (import ../../base-system-config.nix {
          inherit disko;
          mainDevice = "/dev/sda";
          hostName = "marati-nuc";
          timeZone = "Europe/Tallinn";
        })

        {
          users.users.ted = {
            isNormalUser = true;
            # Sudo and docker access for ted
            extraGroups = [ "wheel" "docker" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
            ];
          };

          userbase.users."ted" = {
            fullName = "Ted Steen";
            email = "ted.steen@gmail.com";
            
            # The state versions are required and should stay at the version you
            # originally installed.
            # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
            stateVersion = "24.11";
          };
          
          virtualisation.docker.enable = true;
          
          sops = {
            # Encrypted with `sops -e -i secrets.yaml`, see `.sops.yaml` for recipients.
            defaultSopsFile = ./secrets.yaml;
            secrets = {
              cf_dns_api_token = {
                mode = "0440";
                owner = "ted";
                group = "docker";
              };
            };
          };

          environment.etc."restic/docker-stacks.env".text = ''
            RESTIC_REPOSITORY="/backup/docker-stacks"
            RESTIC_PASSWORD="password"
          '';
          
          services.dockerStack = {
            resticEnvFile = "/etc/restic/docker-stacks.env";
            stacks = {
              infra = {
                path = ./docker/infra;
                # backupSchedule = "Sat 01:00 CET";
              };
            };
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

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = "24.11";
        }
      ];
    };
  };
}