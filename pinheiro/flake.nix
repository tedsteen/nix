{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, home-manager, ... }: let
    linuxDiskConfig = import ../linux-disk-config.nix;
    basicUserConfig = import ../basic-user.nix;
  in {
    nixosConfigurations.pinheiro = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        
        disko.nixosModules.disko
        (linuxDiskConfig { mainDevice = "/dev/sda"; })
        
        ../basic-config.nix
        
        home-manager.nixosModules.home-manager
        (import ../basic-user.nix {
          userName = "ted";
          userEmail = "ted.steen@gmail.com";
          userFullName = "Ted Steen";
          userAuthorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
          ];
        })

        ({ config, pkgs, ... }: {
          networking.hostName = "pinherio-nuc";
          time.timeZone = "Europe/Lisbon";
          console.keyMap = "dvorak";
          boot.loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              ChallengeResponseAuthentication = false;
              PermitRootLogin = "no";
              PubkeyAuthentication = true;
            };
          };

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = "24.11";
          home-manager.users.ted.home.stateVersion = "24.11";
        })
      ];
    };
  };
}