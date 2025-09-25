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
    
    userbase = {
      url = "../../shared";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, disko, home-manager, userbase, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      modules = [
        home-manager.nixosModules.home-manager
        userbase.homeManagerModules.userbase
        ./hardware-configuration.nix
        (import ../base-system-config.nix {
          inherit disko;
          mainDevice = "/dev/vda";
          hostName = "lab";
          timeZone = "Europe/Lisbon";
        })
        {

          users.users.ted = {
            isNormalUser = true;
            shell = pkgs.zsh;
            extraGroups = [ "wheel" ];
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
        }
      ];
    };
  };
}