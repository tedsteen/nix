# Bare minimum linux system configuration
{ hostName, timeZone, username, email, fullName, ... }: { 
  imports = [
    (import ../shared/base-config.nix {
      inherit username email fullName;
    })
  ];
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