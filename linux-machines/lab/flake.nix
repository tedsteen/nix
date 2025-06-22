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
      system = "aarch64-linux";
      
      modules = [
        ./hardware-configuration.nix
        (import ../system-boot-config.nix {
          inherit disko;
          mainDevice = "/dev/vda";
        })
        (import ../../basic-system-config.nix {
          hostName = "lab";
          timeZone = "Europe/Lisbon";
          username = "ted";
          email = "ted.steen@gmail.com";
          fullName = "Ted Steen";
        })

        home-manager.nixosModules.home-manager
        ({ pkgs, ... }: {

          users.users.ted = {
            isNormalUser = true;
            shell = pkgs.zsh;
            extraGroups = [ "wheel" ];
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
          services = {
            openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                ChallengeResponseAuthentication = false;
                PermitRootLogin = "no";
                PubkeyAuthentication = true;
              };
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
        })
      ];
    };
  };
}