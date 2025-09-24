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
      inputs = {
        # nixpkgs.follows = "nixpkgs";
        # nix-darwin.follows  = "darwin";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    roro-ci = {
      url = "path:/Users/tedsteen/git/roro/Room_CITools/nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, sops-nix, roro-ci, ... }: let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
    };

  in {
    darwinConfigurations."teds-mbp" = darwin.lib.darwinSystem {
      inherit system pkgs;

      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        (import ./base-and-user-config.nix {
          inherit pkgs;
          username = "tedsteen";
          fullName = "Ted Steen";
          email = "ted.steen@gmail.com";
        })
        {
          
          networking.computerName = "Ted's MacBook Pro";
          networking.hostName = "teds-mbp";

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
        sops-nix.darwinModules.sops
        roro-ci.darwinModules.github-runner
        (import ./base-and-user-config.nix {
          inherit pkgs;
          username = "tedsteen";
          fullName = "Ted Steen";
          email = "ted.steen@gmail.com";
        })
        ({ config, lib, pkgs, ... } : {
          
          networking.computerName = "Steen's iMac";
          networking.hostName = "steen-imac";

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

          sops = {
            age.sshKeyPaths = [ "/Users/tedsteen/.ssh/random" ];
            # Encrypted with `sops -e -i secrets.yaml`, see `.sops.yaml` for recipients.
            defaultSopsFile = ./secrets.yaml;
            secrets = {
              roro_github_runner_pat = {
                owner = "tedsteen";
              };
            };
          };

          roro.githubRunner = {
            enable = true;
            user = "tedsteen";
            ueInstallsPath = "/Users/Shared/Epic\ Games";
            tokenFile = config.sops.secrets.roro_github_runner_pat.path;
          };

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = 6;
        })
      ];
    };
  };
}
