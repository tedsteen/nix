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
        (import ./base-and-user-config.nix {
          inherit pkgs;
          computerName = "Ted's MacBook Pro";
          username = "tedsteen";
          fullName = "Ted Steen";
          email = "ted.steen@gmail.com";
        })
        {
          users.users.tedsteen = {
            name = "tedsteen";
            home = "/Users/tedsteen";
          };

          home-manager.users.tedsteen = {
            # The state versions are required and should stay at the version you
            # originally installed.
            # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
            home.stateVersion = "24.11";
          };
          # Enable touch to click on the trackpad
          system.defaults.trackpad.Clicking = true;

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = 6;
        }
      ];
    };
    
    darwinConfigurations."steen-imac" = darwin.lib.darwinSystem {
      inherit system pkgs;

      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        (import ./base-and-user-config.nix {
          inherit pkgs;
          computerName = "Steen's iMac";
          username = "tedsteen";
          fullName = "Ted Steen";
          email = "ted.steen@gmail.com";
        })
        {
          users.users.tedsteen = {
            name = "tedsteen";
            home = "/Users/tedsteen";
          };

          home-manager.users.tedsteen = {
            # The state versions are required and should stay at the version you
            # originally installed.
            # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
            home.stateVersion = "24.11";
          };

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = 6;
        }
      ];
    };
  };
}
