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
    
    # # Enable this hack to fix the spotlight search for nix installed apps
    # mac-app-util = {
    #   url = "github:hraban/mac-app-util";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

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
      url = "../shared";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, /* mac-app-util,*/ nix-homebrew, sops-nix, roro-github-runner, userbase, ... }: let
    system = "aarch64-darwin";
    me = { username = "tedsteen"; fullName = "Ted Steen"; email = "ted.steen@gmail.com"; };
  in {
    darwinConfigurations."teds-mbp" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager

        # # Enable this hack to fix the spotlight search for nix installed apps (on a darwin level)
        # mac-app-util.darwinModules.default
        
        userbase.homeManagerModules.userbase
        
        sops-nix.darwinModules.sops
        roro-github-runner.darwinModules.github-runner
        ./base-config.nix
        
        # # Enable this hack to fix the spotlight search for nix installed apps
        # { home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ]; }

        {
          macBaseConfig.username = "${me.username}";

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

          roro.githubRunner = {
            enable = false;
            user = "${me.username}";
          };

          # Enable touch to click on the trackpad
          system.defaults.trackpad.Clicking = true;

          system.stateVersion = 6;
        }
      ];
    };
    
    darwinConfigurations."steen-imac" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        
        # # Enable this hack to fix the spotlight search for nix installed apps
        # mac-app-util.darwinModules.default

        userbase.homeManagerModules.userbase

        #sops-nix.darwinModules.sops
        roro-github-runner.darwinModules.github-runner
        ./base-config.nix

        # # Enable this hack to fix the spotlight search for nix installed apps
        # { home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ]; }

        ({ config, lib, ... } : {
          macBaseConfig.username = "${me.username}";

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

          roro.githubRunner = {
            enable = false;
            user = "${me.username}";
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
