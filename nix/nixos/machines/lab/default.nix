{ ... }:
{
  imports = [
    ../../modules/base.nix
    ./hardware-configuration.nix
  ];

  ted.nixos = {
    disk.device = "/dev/vda";
    hostName = "lab";
    timeZone = "Europe/Lisbon";
    stateVersion = "24.11";
  };
}
