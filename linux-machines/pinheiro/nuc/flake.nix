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
  };

  outputs = { nixpkgs, disko, home-manager, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
        home-manager.nixosModules.home-manager
        ./hardware-configuration.nix
        ../../hardening-config.nix
        ({ pkgs, ... }: import ./docker/docker-stacks.nix {
          inherit pkgs;
          dockerUser = "ted";
        })
        (import ../../system-boot-config.nix {
          inherit disko;
          mainDevice = "/dev/sda";
        })
        (import ../../basic-system-config.nix {
          hostName = "pinheiro-nuc";
          timeZone = "Europe/Lisbon";
        })
        ({ pkgs, ... }: {
          console.keyMap = "dvorak";

          users.users.ted = {
            isNormalUser = true;
            shell = pkgs.zsh;
            # Sudo for ted
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
            ];
          };
          
          home-manager.users."ted" = {
            imports = [
              (import ../../../shared/basic-shell-config.nix {
                email = "ted.steen@gmail.com";
                fullName = "Ted Steen";
              })
            ];
            
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

          # ZFS stuff
          boot = {
            kernelModules = [ "zfs" ];
            supportedFilesystems = [ "zfs" ];
          };

          networking.hostId = "1f666b7f"; # head -c4 /dev/urandom | od -A none -t x4
          services.zfs = {
            
            # TODO: Check https://mynixos.com/options/services.zfs.zed

            autoScrub = {
              enable = true;
              interval = "monthly";
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