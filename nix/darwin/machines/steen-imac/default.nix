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
    inputs.roro-github-runner.darwinModules.github-runner
    ../../modules/base.nix
  ];

  macBaseConfig.user = me;

  networking.computerName = "Steen's iMac";
  networking.hostName = "steen-imac";

  roro.githubRunner = {
    enable = false;
    user = me.username;
  };

  system.stateVersion = 6;
}
