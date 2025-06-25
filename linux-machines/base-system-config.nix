# Bare minimum linux system configuration with a user
{ disko, mainDevice, hostName, timeZone, username, email, fullName, ... }: { 
  imports = [
    disko.nixosModules.disko
    (import ../shared/base-user-config.nix {
      inherit username email fullName;
    })
  ];

  disko.devices = {
    disk.main = {
      device = mainDevice;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "300m";
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
  };
  
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = hostName;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    enableIPv6 = false;
  };

  time.timeZone = timeZone;
  environment.sessionVariables.EDITOR="nvim";

  programs = {
    command-not-found.enable = false;
    zsh.enable = true;
    neovim = {
      enable = true;
    };
  };
}