{
  description = "Full darwin + home-manager + nix-homebrew config for tedsteen";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, ... }: let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    darwinConfigurations."teds-mbp" = darwin.lib.darwinSystem {
      inherit system pkgs;

      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        ./basic-system-config.nix
        ./user-ted.nix
        {
          # Enable touch to click on the trackpad
          system.defaults.trackpad.Clicking = true;

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = 6;
        }
      ];
    };
    
    darwinConfigurations."teds-imac" = darwin.lib.darwinSystem {
      inherit system pkgs;

      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        ./basic-system-config.nix
        ./user-ted.nix
        {
          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = 6;
        }
      ];
    };
  };
}
