{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.pinheiro.url = "./pinheiro";

  outputs = { self, nixpkgs, disko, pinheiro, ... }: {
    nixosConfigurations.pinheiro = pinheiro.nixosConfigurations.pinheiro;
  };
}