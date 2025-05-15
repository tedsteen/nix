# Bare minimum shell configuration
{ email, fullName }:

{ lib, pkgs, ... }: let
  nvimConfigPath = ./nvim;
in {
  home.file.".config/nvim" = {
    source = "${nvimConfigPath}";
    recursive = true;
  };

  home.packages = with pkgs; [    
    # nvim dependencies
    gcc
    unzip
    fd
    ripgrep
    gnumake

    # git
    difftastic
    git-lfs
  ];

  programs = {
    zsh = {
      enable = true;
      # TODO: Or use marlonrichert/zsh-autocomplete?
      enableCompletion = true;
      autosuggestion.enable = true;

      initContent = ''
        # Enable comments in zsh
        setopt interactivecomments
        
        setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
        setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.

        source "${pkgs.zinit}/share/zinit/zinit.zsh"
        # TODO: Enable?
        # zinit compile
        
        zinit light zdharma-continuum/fast-syntax-highlighting
        
        # TODO: Look into this. Perhaps enableCompletion = true is enough?
        # zinit light marlonrichert/zsh-autocomplete

        zinit light MichaelAquilina/zsh-you-should-use
        zinit light zsh-users/zsh-history-substring-search
        # Make up/down arrows for zsh-history-substring-search work
        bindkey '^[[A' history-substring-search-up && bindkey '^[[B' history-substring-search-down

        mkcd() { mkdir -p "$@" && cd "$@"; }
      '';

      shellAliases = {
        ls = lib.mkDefault "ls -hal --color=auto";
        jcurl = "curl -H 'Content-Type: application/json' -H 'Accept: application/json'";

        # git
        gs = "git status";
        ga = "git add";
        gaa = "git add -A";
        gc = "git commit -m";
        gd = "git diff HEAD";
        go = "git push -u origin";
        gco = "git checkout";
        gl = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        gb = "git for-each-ref --sort='-authordate:iso8601' --format=' %(color:green)%(authordate:iso8601)%09%(color:white)%(refname:short)' refs/heads";
        gnuke = "git reset --hard && git clean -fdx";
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
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    git = {
      enable = true;
      userEmail = email;
      userName = fullName;
      extraConfig = {
        init.defaultBranch = "master";
        fetch.prune = true;
        pull.rebase = true;
        push.autoSetupRemote = true;
        diff.external = "difft";
      };
    };
  };
}