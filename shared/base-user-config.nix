# Bare minimum user configuration
{ username, email, fullName }: { config, lib, pkgs, ... }: {
  home-manager.users.${username} = {
    nix = {
      settings.experimental-features = "nix-command flakes";
    };

    home.file = {
      ".config/nvim" = {
        source = ./nvim;
        recursive = true;
      };

      ".tmux.conf".text = ''
        set -g mouse on
      '';
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

      # secrets management
      sops
      age

      # nice to have
      watch
      tree
      htop
      tmux
      jq
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

          # Show listening ports (Linux/Mac)
          ports() {
            if [ "$(uname)" = "Darwin" ]; then
              lsof -i -P -n | grep LISTEN
            else
              netstat -tulanp 2>/dev/null || ss -tulpn
            fi
          }
        '';

        shellAliases = let
          # TODO: Right now we just assume that docker is installed when on macOS. We should actually check for it.
          dockerOn = pkgs.stdenv.isDarwin || config.virtualisation.docker.enable;
        in lib.mkMerge [
          {
            # base aliases
            ls    = lib.mkDefault "ls -hal --color=auto";
            jcurl = "curl -sS -H 'Content-Type: application/json' -H 'Accept: application/json'";

            # git
            gs  = "git status";
            ga  = "git add";
            gaa = "git add -A";
            gc  = "git commit -m";
            gd  = "git diff HEAD";
            go  = "git push -u origin";
            gco = "git checkout";
            gl  = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            gb  = "git for-each-ref --sort='-authordate:iso8601' --format=' %(color:green)%(authordate:iso8601)%09%(color:white)%(refname:short)' refs/heads";
            gnuke = "git reset --hard && git clean -fdx";

            # tmux
            tn  = "tmux new -s";
            ta  = "tmux attach -t";
            tls = "tmux ls";

            grep = "grep --color=auto";
          }

          (lib.mkIf dockerOn {
            dkrm   = "docker ps -aq -f status=exited | xargs -r docker rm -f";
            dkkill = "docker ps -q | xargs -r docker kill";
          })
        ];
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
  };
}
