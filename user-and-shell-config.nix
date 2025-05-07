# Bare minimum user and shell configuration
{ userName, userEmail, userFullName, userAuthorizedKeys }:

{ config, lib, pkgs, ... }: {
  users.users.${userName} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = userAuthorizedKeys;
  };

  home-manager.users.${userName} = { pkgs, ... }: {
    programs = {
      fish = {
        enable = true;

        shellAbbrs = {
          ls="ls -hal";
          jcurl="curl -H 'Content-Type: application/json' -H 'Accept: application/json'";

          # git
          gs="git status";
          ga="git add";
          gaa="git add -A";
          gc="git commit -m";
          gd="git diff HEAD";
          go="git push -u origin";
          gco="git checkout";
          # Pretty git log
          gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          # All local branches in the order of their last commit
          gb="git for-each-ref --sort='-authordate:iso8601' --format=' %(color:green)%(authordate:iso8601)%09%(color:white)%(refname:short)' refs/heads";
          gnuke="git reset --hard; git clean -fdx";
        };
      };

      starship = {
        enable = true;
        settings = {
          command_timeout = 1000;

          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
          };

          directory = {
            format = " [$path]($style)[$read_only]($read_only_style) ";
            home_symbol = "⌂";
          };

          cmd_duration = {
            min_time = 1000;
            format = " [⧗$duration]($style) ";
            style = "dimmed 8";
          };
        };
      };

      neovim = {
        enable = true;

        extraConfig = ''
            " set tabs to 2 spaces
            set tabstop=2
            set shiftwidth=2
            " expand tabs to spaces
            set expandtab
            " try to be smart (increase the indenting level after ‘{’,
            " decrease it after ‘}’, and so on):
            " set smartindent
        '';
      };

      git = {
        enable = true;
        userEmail = userEmail;
        userName = userFullName;
        extraConfig = {
          init.defaultBranch = "master";
          fetch.prune = true;
          pull.rebase = true;
          push.autoSetupRemote = true;
        };
      };
    };
  };
}