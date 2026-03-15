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
    inputs.sops-nix.darwinModules.sops
    inputs.roro-github-runner.darwinModules.github-runner
    ../../modules/base.nix
  ];

  macBaseConfig.username = me.username;

  sops.defaultSopsFile = ../../secrets.yaml;

  networking.computerName = "Ted's MacBook Pro";
  networking.hostName = "teds-mbp";

  userbase.users.${me.username} = {
    fullName = me.fullName;
    email = me.email;
    stateVersion = "24.11";
  };

  roro.githubRunner = {
    enable = false;
    user = me.username;
  };

  system.defaults.trackpad.Clicking = true;

  system.stateVersion = 6;
}
