{ inputs, lib, config, ... }:

let
  cfg = config.nixosBaseConfig;
  mkSudoRule = username: {
    users = [ username ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  };
in
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.userbase.homeManagerModules.userbase
  ];

  options.nixosBaseConfig.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
      options = {
        fullName = lib.mkOption {
          type = lib.types.str;
          description = "Full name for the user.";
        };

        email = lib.mkOption {
          type = lib.types.str;
          description = "Email for the user.";
        };

        homeStateVersion = lib.mkOption {
          type = lib.types.str;
          description = "Home Manager state version for the user.";
        };

        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "SSH keys allowed for the user.";
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional Unix groups for the user.";
        };

        sudoNoPassword = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether the user gets passwordless sudo.";
        };
      };
    }));
    default = { };
    description = "Users managed by the shared NixOS base-config.";
  };

  config = {
    disko.devices.disk.main = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "300M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    networking = {
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
      enableIPv6 = false;
    };

    programs.command-not-found.enable = false;

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };

    services.journald.extraConfig = ''
      SystemMaxUse=500M
      MaxFileSec=1month
    '';

    zramSwap = {
      enable = true;
      memoryPercent = 40;
      algorithm = "zstd";
    };

    services.fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
      bantime = "1h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        ChallengeResponseAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
      };
    };

    security.sudo.extraRules = lib.flatten (lib.mapAttrsToList
      (username: user: lib.optional user.sudoNoPassword (mkSudoRule username))
      cfg.users);

    users.users = lib.mapAttrs
      (username: user: {
        isNormalUser = true;
        extraGroups = [ "wheel" ] ++ user.extraGroups;
        openssh.authorizedKeys.keys = user.authorizedKeys;
      })
      cfg.users;

    userbase.users = lib.mapAttrs
      (_: user: {
        fullName = user.fullName;
        email = user.email;
        stateVersion = user.homeStateVersion;
      })
      cfg.users;
  };
}
