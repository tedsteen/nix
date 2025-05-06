{ nixpkgs, disko, configuration, linuxDiskConfig }:

{ system, mainDevice, hostName, timeZone, hardwareConfig }:

nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    disko.nixosModules.disko
    hardwareConfig
    (linuxDiskConfig { inherit mainDevice; })
    configuration
    ({ config, pkgs, ... }: {
      networking.hostName = hostName;
      time.timeZone = timeZone;
      console.keyMap = "dvorak";
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
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
    })
  ];
}