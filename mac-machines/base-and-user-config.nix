{pkgs, computerName, username, email, fullName, ...}: {
  imports = [
    (import ../shared/base-user-config.nix {
        inherit username email fullName;
    })
  ];

  networking.computerName = "${computerName}";
  nixpkgs.config.allowUnfree = true;
  security.pam.services.sudo_local.touchIdAuth = true;
  system = {
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
    
    defaults = {
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

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "${username}";
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
      "sdl2" # NOTE: This has to be here because mesen2 has hardcoded sdl2 path
      # "lume"
    ];
    casks = [
      "balenaetcher"
      "discord"
      "ghostty"
      "gifox"
      "grandperspective"
      "handbrake"
      "iina"
      "mullvadvpn"
      "ocenaudio"
      "orbstack"
      "raycast"
      "signal"
      "spotify"
      "stats"
      "transmission"
      "utm"
      "visual-studio-code"
      # TODO: Check out zed
    ];
  };

  home-manager.users.${username} = {
      home.username = "${username}";
      home.homeDirectory = "/Users/${username}";

      # The home.packages option allows you to install Nix packages into your
      # environment.
      home.packages = with pkgs; [
        # General stuff
        cmake
        #pkg-config
        
        # NOTE: The following two package is required for rust, [see](https://github.com/NixOS/nixpkgs/issues/206242).
        #       Also see the LIBRARY_PATH further down, it's part of this fix
        libiconv
        
        # NES stuff
        cc65
        python3

        # Rust stuff
        cargo
        rustc
        rustfmt
        clippy
        rust-analyzer
        gdb

        # Node stuff
        nodejs
        pnpm
        yarn
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
      #  /etc/profiles/per-user/${username}/etc/profile.d/hm-session-vars.sh
      #
      home.sessionVariables = {
        # EDITOR = "emacs";
        
        # Part of the fix for rust, see the packages above
        LIBRARY_PATH = "${pkgs.libiconv}/lib";
        
        # Use clang instead of gcc
        CC = "clang";
        CXX = "clang++";
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

      # programs.zsh.initContent = ''
      #   # # TODO: Fix broken nix after macOS upgrade (not needed?)
      #   # [[ ! $(command -v nix) && -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]] && source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      # '';

      programs.zsh.shellAliases = {
        samba-nuc = "open smb://guest:guest@nuc.pinheiro.s3n.io/everything";
        samba-mister = "open smb://root:1@mister/sdcard";
      };

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