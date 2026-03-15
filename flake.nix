{
  description = "Root flake for all NixOS and nix-darwin machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    roro-github-runner = {
      url = "git+ssh://git@github.com/RoroInteractive/Room_CITools?dir=nix/github-runner&rev=4b0f3ceb054c8985115fbb82c9af8d331e542707&submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
      inputs.sops-nix.follows = "sops-nix";
    };

    userbase = {
      url = "path:./shared";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ darwin, nixpkgs, ... }:
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
