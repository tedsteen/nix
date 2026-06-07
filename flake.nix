{
  description = "Root flake for all NixOS and nix-darwin machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    userbase = {
      url = "path:./shared";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ darwin, nixpkgs, nixpkgs-darwin, ... }:
    let
      mkNixosMachine = machine: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nix/nixos/machines/${machine}/default.nix
        ];
      };

      mkDarwinMachine = machine: darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./nix/darwin/machines/${machine}/default.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        pinheiro-nuc = mkNixosMachine "pinheiro-nuc";
        marati-nuc = mkNixosMachine "marati-nuc";
        lab = mkNixosMachine "lab";
      };

      darwinConfigurations = {
        teds-mbp = mkDarwinMachine "teds-mbp";
        steen-imac = mkDarwinMachine "steen-imac";
      };
    };
}
