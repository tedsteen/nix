{ inputs, ... }:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.home-manager.darwinModules.home-manager
    inputs.userbase.homeManagerModules.userbase
    ../../modules/base.nix
  ];

  macBaseConfig.user = {
    username = "tedsteen";
    fullName = "Ted Steen";
    email = "ted.steen@gmail.com";
    homeStateVersion = "24.11";
  };

  networking.computerName = "Steen's iMac";
  networking.hostName = "steen-imac";

  system.stateVersion = 6;
}
