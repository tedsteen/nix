{ inputs, ... }:
let
  me = {
    username = "tedsteen";
    fullName = "Ted Steen";
    email = "ted.steen@gmail.com";
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

  macBaseConfig.username = me.username;

  networking.computerName = "Steen's iMac";
  networking.hostName = "steen-imac";

  userbase.users.${me.username} = {
    fullName = me.fullName;
    email = me.email;
    stateVersion = "24.11";
  };

  roro.githubRunner = {
    enable = false;
    user = me.username;
  };

  system.stateVersion = 6;
}
