{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    userbase = {
      url = "path:../../shared";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      mkNixosMachine = machine: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/${machine}/default.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        pinheiro-nuc = mkNixosMachine "pinheiro-nuc";
        marati-nuc = mkNixosMachine "marati-nuc";
        lab = mkNixosMachine "lab";
      };
    };
}
