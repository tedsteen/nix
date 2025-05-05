{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, disko, ... }: let
    mkGenericLinuxSystem = { system, mainDevice, hostName, timeZone }: nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        ./hardware-configuration.nix
        (import ./linux-disk-config.nix { inherit mainDevice; })
        ./configuration.nix
        ({ config, pkgs, ... }: {

          networking.hostName = hostName;
          time.timeZone = timeZone;
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
  in {
    nixosConfigurations = {
      pinheiro = mkGenericLinuxSystem {
        system = "x86_64-linux";
        mainDevice = "/dev/sda";
        hostName = "marati-nuc";
        timeZone = "Europe/Lisbon";
      };
    };
  };
}
