{ pkgs, ... }:

{
  nix.settings.experimental-features = "nix-command flakes";
  environment.sessionVariables.EDITOR="nvim";

  programs = {
    command-not-found.enable = false;
    fish.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}