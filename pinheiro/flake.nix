{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, disko, ... }: let
    linuxDiskConfig = import ../linux-disk-config.nix;
  in {
    nixosConfigurations.pinheiro = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hardware-configuration.nix
        (linuxDiskConfig { mainDevice = "/dev/sda"; })
        ../configuration.nix
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
        })
      ];
    };
  };
}