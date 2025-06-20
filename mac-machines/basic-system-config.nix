{
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
    user = "tedsteen";
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
      "numi"
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
}
