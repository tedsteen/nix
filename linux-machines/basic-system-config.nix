# Bare minimum linux system configuration
{ hostName, timeZone, ... }: {  
  networking.hostName = hostName;
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