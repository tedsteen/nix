{ userName, userEmail, userFullName, userSshKey }:

{ config, lib, pkgs, ... }: {
  users.users.${userName} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ userSshKey ];
  };

  security.sudo.extraRules = [
    {
      users = [ userName ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    }
  ];

  home-manager.users.${userName} = { pkgs, ... }: {
    programs.git = {
      enable = true;
      userEmail = userEmail;
      userName = userFullName;
    };
  };
}