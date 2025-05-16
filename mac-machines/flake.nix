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
    basic = import ../shared/basic-shell-config.nix {
      email = "ted.steen@gmail.com";
      fullName = "Ted Steen";
    };
    docker = import ../shared/docker-config.nix;
  in {
    darwinConfigurations."teds-mbp" = darwin.lib.darwinSystem {
      inherit system pkgs;

      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          security.pam.services.sudo_local.touchIdAuth = true;
          system = {
            # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
            activationScripts.postUserActivation.text = ''
              # activateSettings -u will reload the settings from the database and apply them to the current session,
              # so we do not need to logout and login again to make the changes take effect.
              /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
            '';
            
            defaults = {
              # Enable touch to click on the trackpad
              trackpad.Clicking = true;

              finder = {
                _FXShowPosixPathInTitle = true;  # show full path in finder title
                FXPreferredViewStyle = "clmv";
              };

              dock.orientation = "bottom";
              dock.autohide = true;
              dock.autohide-delay = 0.0;
              dock.autohide-time-modifier = 0.3;
              dock.tilesize = 36;
              dock.magnification = false;
              
              dock.expose-animation-duration = 0.01;
              dock.expose-group-apps = true;
              
              NSGlobalDomain = {
                InitialKeyRepeat = 15; # 120 (1800 ms), 94, 68, 35, 25, 15 (225 ms)
                KeyRepeat = 2;         # 120 (1800 ms), 90, 60, 30, 12, 6, 2 (30 ms)

                NSAutomaticCapitalizationEnabled = false;
                NSAutomaticDashSubstitutionEnabled = false;
                NSAutomaticPeriodSubstitutionEnabled = false;
                NSAutomaticQuoteSubstitutionEnabled = false;
                NSAutomaticSpellingCorrectionEnabled = false;
              };

              CustomUserPreferences = {
                "com.apple.dock" = {
                  # Swipe down with three or four fingers
                  showAppExposeGestureEnabled = true;
                };
                "com.apple.finder" = {
                  ShowExternalHardDrivesOnDesktop = true;
                  ShowHardDrivesOnDesktop = true;
                  ShowMountedServersOnDesktop = true;
                  ShowRemovableMediaOnDesktop = true;
                  _FXSortFoldersFirst = true;
                  # When performing a search, search the current folder by default
                  FXDefaultSearchScope = "SCcf";
                };
                "com.apple.desktopservices" = {
                  # Avoid creating .DS_Store files on network or USB volumes
                  DSDontWriteNetworkStores = true;
                  DSDontWriteUSBStores = true;
                };
                "com.apple.screensaver" = {
                  # Require password immediately after sleep or screen saver begins
                  askForPassword = 1;
                  askForPasswordDelay = 5;
                };
                "com.apple.screencapture" = {
                  location = "~/Desktop";
                  type = "png";
                };
                "com.apple.print.PrintingPrefs" = {
                  # Automatically quit printer app once the print jobs complete
                  "Quit When Finished" = true;
                };
                "com.apple.SoftwareUpdate" = {
                  AutomaticCheckEnabled = true;
                  # Check for software updates daily, not just once per week
                  ScheduleFrequency = 1;
                  # Download newly available updates in background
                  AutomaticDownload = 1;
                  # Install System data files & security updates
                  CriticalUpdateInstall = 1;
                };
                # Prevent Photos from opening automatically when devices are plugged in
                "com.apple.ImageCapture".disableHotPlug = true;
                # Turn on app auto-update
                "com.apple.commerce".AutoUpdate = true;
              };
              loginwindow.GuestEnabled = false;
            };
          };

          users.users.tedsteen = {
            name = "tedsteen";
            home = "/Users/tedsteen";
          };

          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "tedsteen";
          };

          homebrew = {
            enable = true;
            onActivation.autoUpdate = true;
            onActivation.cleanup = "zap";
            masApps = {
              "DigiDoc4 Client" = 1370791134;
              "Messenger" = 1480068668;
              "The Unarchiver" = 425424353;
              "Ticktick" = 966085870;
              "WhatsApp" = 310633997;
              "Wireguard" = 1451685025;
            };
            taps = [ "homebrew/core" "homebrew/cask" ];
            brews = [
              "sdl2"
            ];
            casks = [
              "balenaetcher"
              "discord"
              "docker"
              "ghostty"
              "gifox"
              "grandperspective"
              "handbrake"
              "iina"
              "mullvadvpn"
              "numi"
              "ocenaudio"
              "signal"
              "spotify"
              "stats"
              "transmission"
              "visual-studio-code"
            ];
          };

          # The state versions are required and should stay at the version you
          # originally installed.
          # DON'T CHANGE THEM UNLESS YOU KNOW WHAT YOU'RE DOING!
          system.stateVersion = 6;

          home-manager.users.tedsteen = {
            imports = [
              basic
              docker
            ];

            nixpkgs.config.allowUnfree = true; 
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
