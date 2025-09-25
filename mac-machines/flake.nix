{
  description = "Full darwin + home-manager + nix-homebrew config for my macs";

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

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    roro-ci = {
      url = "git+ssh://git@github.com/RoroInteractive/Room_CITools?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
      inputs.sops-nix.follows = "sops-nix";
    };

    userbase = {
      url = "../shared";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, sops-nix, roro-ci, userbase, ... }: let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
    };
    me = { username = "tedsteen"; fullName = "Ted Steen"; email = "ted.steen@gmail.com"; };
  in {
    darwinConfigurations."teds-mbp" = darwin.lib.darwinSystem {
      inherit system pkgs;

      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        userbase.homeManagerModules.userbase
        (import ./base-config.nix {
          inherit pkgs;
          username = "${me.username}";
        })
        {
          networking.computerName = "Ted's MacBook Pro";
          networking.hostName = "teds-mbp";
          
          userbase.users.${me.username} = {
            fullName = "${me.fullName}";
            email = "${me.email}";
            
            # The state versions are required and should stay at the version you
            # originally installed.
            # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
            stateVersion = "24.11";
          };

          # Enable touch to click on the trackpad
          system.defaults.trackpad.Clicking = true;

          system.stateVersion = 6;
        }
      ];
    };
    
    darwinConfigurations."steen-imac" = darwin.lib.darwinSystem {
      inherit system pkgs;

      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        userbase.homeManagerModules.userbase

        sops-nix.darwinModules.sops
        roro-ci.darwinModules.github-runner
        (import ./base-config.nix {
          inherit pkgs;
          username = "${me.username}";
        })
        ({ config, lib, pkgs, ... } : {
          
          networking.computerName = "Steen's iMac";
          networking.hostName = "steen-imac";

          userbase.users.${me.username} = {
            fullName = "${me.fullName}";
            email = "${me.email}";
            
            # The state versions are required and should stay at the version you
            # originally installed.
            # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
            stateVersion = "24.11";
          };

          sops = {
            age.sshKeyPaths = [ "/Users/${me.username}/.ssh/random" ];
            # Encrypted with `sops -e -i secrets.yaml`, see `.sops.yaml` for recipients.
            defaultSopsFile = ./secrets.yaml;
            secrets = {
              roro_github_runner_pat = {
                owner = "${me.username}";
              };
            };
          };

          roro.githubRunner = {
            enable = true;
            user = "${me.username}";
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
