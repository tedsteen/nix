{
  description = "Home Manager configuration of tedsteen";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."tedsteen" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          (import ./basic-shell-config.nix {
            email = "ted.steen@gmail.com";
            fullName = "Ted Steen";
          })
          ./home.nix
          ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
