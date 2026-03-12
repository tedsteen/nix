{
  description = "Userbase: reusable HM module for my minimal user configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixvim, ... }: {
    # Single HM module you can import from other flakes.
    homeManagerModules.userbase = { lib, pkgs, config, ... }: {
      options.userbase.users = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
          options = {
            email        = lib.mkOption { type = lib.types.str; };
            fullName     = lib.mkOption { type = lib.types.str; };
            stateVersion = lib.mkOption { type = lib.types.str; };
          };
        }));
        default = {};
        description = "users attrset: { <username> = { email, fullName, stateVersion }; }";
      };

      config = let
        cfg = config.userbase.users;
        # TODO: Right now we just assume that docker is installed when on macOS. We should actually check for it.
        dockerOn = pkgs.stdenv.isDarwin || (config.virtualisation.docker.enable or false);
        
        mkUserCfg = username: u: {
          imports = [ nixvim.homeModules.nixvim ];

          # Let Home Manager install and manage itself.
          programs.home-manager.enable = true;

          home.stateVersion = u.stateVersion;

          home.file = {
            ".tmux.conf".text = ''
              set -g mouse on
            '';
          };

          home.sessionVariables.EDITOR = lib.mkDefault "nvim";
          home.sessionVariables.VISUAL = lib.mkDefault "nvim";

          home.packages = with pkgs; [    
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

                dev() {
                  PROFILES="$*" nix develop --impure path:${./dev} --no-write-lock-file --command zsh
                }
              '';

              shellAliases = lib.mkMerge [
                {
                  # base aliases
                  ls    = lib.mkDefault "ls -hal --color=auto";
                  jcurl = "curl -sS -H 'Content-Type: application/json' -H 'Accept: application/json'";
                  grep = "grep --color=auto";

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
                }

                (lib.mkIf dockerOn {
                  dkrm   = "docker ps -aq -f status=exited | xargs -r docker rm -f";
                  dkkill = "docker ps -q | xargs -r docker kill";
                  dkpruneall = "docker system prune --all --volumes";
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

            ssh = {
              enable = true;
              
              enableDefaultConfig = false;
              matchBlocks."*" = {
                forwardAgent = false;
                addKeysToAgent = "yes";
                compression = false;
                serverAliveInterval = 60;
                serverAliveCountMax = 10;
                hashKnownHosts = false;
                userKnownHostsFile = "~/.ssh/known_hosts";
                controlMaster = "no";
                controlPath = "~/.ssh/master-%r@%n:%p";
                controlPersist = "no";
              };
            };

            nixvim = {
              enable = true;
              viAlias = true;
              vimAlias = true;

              extraPackages = with pkgs; [
                fd
                ripgrep
                shellcheck
                shfmt
              ];

              opts = {
                number = true;
                relativenumber = true;
                expandtab = true;
                shiftwidth = 2;
                tabstop = 2;
                smartindent = true;
                ignorecase = true;
                smartcase = true;
                signcolumn = "yes";
                termguicolors = true;
                updatetime = 250;
              };

              diagnostic.settings = {
                severity_sort = true;
                virtual_text = true;
              };

              plugins = {
                lsp = {
                  enable = true;
                  servers.bashls = {
                    enable = true;
                    filetypes = [ "bash" "sh" ];
                  };
                };

                treesitter = {
                  enable = true;
                  grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
                    bash
                    lua
                    markdown
                    nix
                    query
                    regex
                    vim
                    vimdoc
                  ];

                  highlight.enable = true;
                  indent.enable = true;
                };

                lint = {
                  enable = true;
                  lintersByFt = {
                    bash = [ "shellcheck" ];
                    sh = [ "shellcheck" ];
                  };
                };

                conform-nvim = {
                  enable = true;
                  settings = {
                    format_on_save = {
                      lsp_format = "fallback";
                      timeout_ms = 500;
                    };

                    formatters_by_ft = {
                      bash = [ "shfmt" ];
                      sh = [ "shfmt" ];
                    };
                  };
                };
              };
            };

            git = {
              enable = true;
              settings = {
                user = {
                  user.email = u.email;
                  user.name = u.fullName;
                };

                init.defaultBranch = "master";
                fetch.prune = true;
                pull.rebase = true;
                push.autoSetupRemote = true;
                diff.external = "difft";
              };
            };
          };
        };
      in {
        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users = lib.mapAttrs mkUserCfg cfg;
        
        # To be able to set users.users.*.shell to zsh you need to enable the zsh program here.
        programs.zsh.enable = true;
        users.users = lib.mapAttrs (_: _: {
          shell = pkgs.zsh;
        }) cfg;
      };
    };
  };
}
