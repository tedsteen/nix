# Base config shared by all my macs
{config, lib, pkgs, ...}:
let
  cfg = config.macBaseConfig;
  user = cfg.user;
  username = user.username;
in {
  options.macBaseConfig.user = lib.mkOption {
    type = lib.types.submodule {
      options = {
        username = lib.mkOption {
          type = lib.types.str;
          description = "Primary user for mac base-config.";
        };

        fullName = lib.mkOption {
          type = lib.types.str;
          description = "Full name for the primary user.";
        };

        email = lib.mkOption {
          type = lib.types.str;
          description = "Email for the primary user.";
        };

        homeStateVersion = lib.mkOption {
          type = lib.types.str;
          description = "Home Manager state version for the primary user.";
        };
      };
    };
    description = "Primary user managed by the shared mac base-config.";
  };
  config = {
    security.pam.services.sudo_local.touchIdAuth = true;
    system = {
      primaryUser = username;
      activationScripts.kickStartScript.text = ''
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';

      defaults = {
        finder = {
          _FXShowPosixPathInTitle = true;
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
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
        };

        CustomUserPreferences = {
          "com.apple.dock" = {
            showAppExposeGestureEnabled = true;
          };
          "com.apple.finder" = {
            ShowExternalHardDrivesOnDesktop = true;
            ShowHardDrivesOnDesktop = true;
            ShowMountedServersOnDesktop = true;
            ShowRemovableMediaOnDesktop = true;
            _FXSortFoldersFirst = true;
            FXDefaultSearchScope = "SCcf";
          };
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          "com.apple.screensaver" = {
            askForPassword = 1;
            askForPasswordDelay = 5;
          };
          "com.apple.screencapture" = {
            location = "~/Desktop";
            type = "png";
          };
          "com.apple.print.PrintingPrefs" = {
            "Quit When Finished" = true;
          };
          "com.apple.SoftwareUpdate" = {
            AutomaticCheckEnabled = true;
            ScheduleFrequency = 1;
            AutomaticDownload = 1;
            CriticalUpdateInstall = 1;
          };
          "com.apple.ImageCapture".disableHotPlug = true;
          "com.apple.commerce".AutoUpdate = true;
        };
        loginwindow.GuestEnabled = false;
      };
    };
    
    nix = {
      gc = {
        automatic = true;
        interval = { Weekday = 7; Hour = 3; Minute = 15; };
        options = "--delete-older-than 14d";
      };

      optimise = {
        automatic = true;
        interval = { Weekday = 7; Hour = 4; Minute = 15; };
      };

      settings = {
        trusted-users = [ "@admin" "tedsteen" ];
        builders-use-substitutes = true;
      };

      linux-builder = {
        enable = true;
        systems = [ "aarch64-linux" "x86_64-linux" ];
        supportedFeatures = [ "kvm" "benchmark" "big-parallel" ];
        config = { lib, ... }: {
          boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
          virtualisation.cores = lib.mkForce 8;
          virtualisation.memorySize = lib.mkForce 16384;
        };
      };
    };

    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      user = username;
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
      global.autoUpdate = true;

      masApps = {
        "Calca" = 635758264;
        "DigiDoc4 Client" = 1370791134;
        "Messenger" = 1480068668;
        "The Unarchiver" = 425424353;
        "Ticktick" = 966085870;
        "WhatsApp" = 310633997;
        "Wireguard" = 1451685025;
      };
      taps = [ ];
      brews = [
        "sdl2"
      ];
      casks = [
        "balenaetcher"
        "discord"
        "ghostty"
        "gifox"
        "grandperspective"
        "handbrake-app"
        "iina"
        "mullvad-vpn"
        "ocenaudio"
        "orbstack"
        "raycast"
        "signal"
        "spotify"
        "stats"
        "tailscale-app"
        "transmission"
        "utm"
        "visual-studio-code"
        "zed"
      ];
    };

    users.users.${username} = {
      home = "/Users/${username}";
    };

    userbase.users.${username} = {
      fullName = user.fullName;
      email = user.email;
      stateVersion = user.homeStateVersion;
    };

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        go
      ];

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

      programs = {
        zsh.shellAliases = {
          samba-nuc = "open smb://guest:guest@nuc.pinheiro.s3n.io/everything";
          samba-mister = "open smb://root:1@mister/sdcard";
        };

        ssh.extraConfig = ''
          Host *
            SetEnv TERM=xterm-256color
        '';

        nixvim.plugins = {
          lsp.servers.taplo.enable = true;
          conform-nvim.settings.formatters_by_ft.rust = [ "rustfmt" ];
          treesitter.grammarPackages = lib.mkAfter (with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            rust
            toml
          ]);

          crates = {
            enable = true;
            settings = {
              autoload = true;
              autoupdate = true;
              smart_insert = true;
            };
          };

          rustaceanvim = {
            enable = true;
            settings = {
              tools.enable_clippy = true;
              server.default_settings."rust-analyzer" = {
                cargo = {
                  allFeatures = true;
                  buildScripts.enable = true;
                };
                check.command = "clippy";
                completion.autoimport.enable = true;
                procMacro.enable = true;
              };
            };
          };
        };
      };
    };
  };
}
