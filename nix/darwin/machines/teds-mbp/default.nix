{ inputs, ... }:
let
  me = {
    username = "tedsteen";
    fullName = "Ted Steen";
    email = "ted.steen@gmail.com";
    homeStateVersion = "24.11";
  };
in
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.home-manager.darwinModules.home-manager
    inputs.userbase.homeManagerModules.userbase
    inputs.sops-nix.darwinModules.sops
    ../../modules/base.nix
  ];

  macBaseConfig.user = me;

  sops.defaultSopsFile = ../../secrets.yaml;

  networking.computerName = "Ted's MacBook Pro";
  networking.hostName = "teds-mbp";

  system.defaults.trackpad.Clicking = true;

  system.stateVersion = 6;
}
