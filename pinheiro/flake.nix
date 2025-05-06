{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, disko, ... }: let
    configuration = ../configuration.nix;
    linuxDiskConfig = import ../linux-disk-config.nix;
    mkGenericLinuxSystem = import ../lib/mkGenericLinuxSystem.nix {
      inherit nixpkgs disko configuration linuxDiskConfig;
    };
  in {
    nixosConfigurations.pinheiro = mkGenericLinuxSystem {
      system = "x86_64-linux";
      mainDevice = "/dev/sda";
      hostName = "pinherio-nuc";
      timeZone = "Europe/Lisbon";
      hardwareConfig = ./hardware-configuration.nix;
      extraModules = [
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs; [ wget ];
        })
      ];
    };
  };
}