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
        {
          # Enable touch to click on the trackpad
          system.defaults.trackpad.Clicking = true;

          users.users.tedsteen = {
            name = "tedsteen";
            home = "/Users/tedsteen";
          };

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = 6;

          home-manager.users.tedsteen = {
            imports = [
              (import ../shared/basic-shell-config.nix {
                email = "ted.steen@gmail.com";
                fullName = "Ted Steen";
              })
              ../shared/docker-config.nix
            ];

            home.username = "tedsteen";
            home.homeDirectory = "/Users/tedsteen";

            # The state versions are required and should stay at the version you
            # originally installed.
            # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
            home.stateVersion = "24.11";

            # The home.packages option allows you to install Nix packages into your
            # environment.
            home.packages = with pkgs; [
              cc65
              python3
            ];

            # Home Manager is pretty good at managing dotfiles. The primary way to manage
            # plain files is through 'home.file'.
            home.file = {
              # # Building this configuration will create a copy of 'dotfiles/screenrc' in
              # # the Nix store. Activating the configuration will then make '~/.screenrc' a
              # # symlink to the Nix store copy.
              # ".screenrc".source = dotfiles/screenrc;

              # # You can also set the file content immediately.
              # ".gradle/gradle.properties".text = ''
              #   org.gradle.console=verbose
              #   org.gradle.daemon.idletimeout=3600000
              # '';
            };

            # Home Manager can also manage your environment variables through
            # 'home.sessionVariables'. These will be explicitly sourced when using a
            # shell provided by Home Manager. If you don't want to manage your shell
            # through Home Manager then you have to manually source 'hm-session-vars.sh'
            # located at either
            #
            #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
            #
            # or
            #
            #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
            #
            # or
            #
            #  /etc/profiles/per-user/tedsteen/etc/profile.d/hm-session-vars.sh
            #
            home.sessionVariables = {
              # EDITOR = "emacs";
            };

            # Let Home Manager install and manage itself.
            programs.home-manager.enable = true;
            
            home.file.".config/ghostty/config".text = ''
              background-opacity = 0.95
              background-blur = true
              macos-non-native-fullscreen = true
              keybind = super+alt+left=previous_tab
              keybind = super+alt+right=next_tab
              keybind = super+up=goto_split:up
              keybind = super+down=goto_split:down
              keybind = super+left=goto_split:left
              keybind = super+right=goto_split:right
              window-vsync = true
            '';
            
            programs.zsh.initContent = ''
              # # TODO: Fix broken nix after macOS upgrade (not needed?)
              # [[ ! $(command -v nix) && -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]] && source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
            '';

            programs.ssh = {
              enable = true;
              extraConfig = ''
                # Fix for ghostty https://ghostty.org/docs/help/terminfo#configure-ssh-to-fall-back-to-a-known-terminfo-entry
                Host *
                  SetEnv TERM=xterm-256color
              '';
            };
          };
        }
      ];
    };
  };
}
