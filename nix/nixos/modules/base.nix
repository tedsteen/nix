{ inputs, lib, config, ... }:

let
  cfg = config.ted.nixos;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.userbase.homeManagerModules.userbase
  ];

  options.ted.nixos = {
    disk.device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/sda";
      description = "Primary system disk device path used by disko.";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      description = "System hostname.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      description = "System timezone.";
    };

    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "NixOS state version for this machine.";
    };

    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "ted";
        description = "Primary login user.";
      };

      fullName = lib.mkOption {
        type = lib.types.str;
        default = "Ted Steen";
        description = "Full name for the primary user.";
      };

      email = lib.mkOption {
        type = lib.types.str;
        default = "ted.steen@gmail.com";
        description = "Email for the primary user.";
      };

      homeStateVersion = lib.mkOption {
        type = lib.types.str;
        default = "24.11";
        description = "Home Manager state version for the primary user.";
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
        ];
        description = "SSH keys allowed for the primary user.";
      };
    };
  };

  config = {
    disko.devices.disk.main = {
      device = cfg.disk.device;
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
      hostName = cfg.hostName;
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
      enableIPv6 = false;
      firewall = {
        enable = true;
        checkReversePath = "loose";
      };
    };

    time.timeZone = cfg.timeZone;

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

    security.sudo.extraRules = [
      {
        users = [ cfg.user.name ];
        commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
      }
    ];

    users.users.${cfg.user.name} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = cfg.user.authorizedKeys;
    };

    userbase.users.${cfg.user.name} = {
      fullName = cfg.user.fullName;
      email = cfg.user.email;
      stateVersion = cfg.user.homeStateVersion;
    };

    system.stateVersion = cfg.stateVersion;
  };
}
