{ config, lib, pkgs, ... }:
with lib;
{
  options.services.dockerStack = {
    resticEnvFile = mkOption {
      type        = types.path;
      description = "Environment for restic.";
    };

    stacks = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options.backupSchedule = mkOption {
          type        = types.nullOr types.str;   # null ⇒ no timer
          default     = null;
          description = "systemd OnCalendar spec (null for manual-only).";
        };
        options.path = mkOption {
          type        = types.path;
          description = "Path to the stack directory.";
        };
      }));
      default     = {};
      description = "Compose stacks to configure and back up, keyed by stack name.";
    };
  };

  config = let
    cfg = config.services.dockerStack;
  in mkIf (cfg.stacks != {}) (let
    unitName   = name: "restic-backup-${name}";
  in {
    systemd.services = let
      mkBackupScript = name: pkgs.writeShellApplication {
        name = "restic-${name}-backup";
        runtimeInputs = [ pkgs.restic pkgs.docker pkgs.bash pkgs.jq ];
        text = ''
          set -euo pipefail
          STACK_NAME=${name}

          if ! restic snapshots &>/dev/null; then
            echo "Initialising repo @ $RESTIC_REPOSITORY"
            restic init
          fi

          readarray -t VOLUMES < <(
            docker volume ls \
              --filter "label=com.docker.compose.project=$STACK_NAME" \
              --format '{{json .}}' \
            | jq -r '.Name'
          )
          
          if ((''${#VOLUMES[@]} == 0)); then
            echo "No volumes for $STACK_NAME, bailing"
            exit 0
          fi
          
          readarray -t MOUNTPOINTS < <(docker volume inspect "''${VOLUMES[@]}" | jq -r '.[].Mountpoint')
          readarray -t RUNNING_SERVICES < <(
            docker compose -p "$STACK_NAME" ps --format json | jq -r 'select(.State=="running") | .Service'
          )

          start_stack() { :; } # no-op by default, will be overridden if there are running services
          if ((''${#RUNNING_SERVICES[@]})); then
            docker compose -p "$STACK_NAME" stop "''${RUNNING_SERVICES[@]}"
            start_stack() {
              docker compose -p "$STACK_NAME" start "''${RUNNING_SERVICES[@]}"
            }
            # Make sure the stack is started if the backup fails.
            trap start_stack EXIT
          fi

          RES_HOST="docker-$STACK_NAME"
          restic backup "''${MOUNTPOINTS[@]}" --host $RES_HOST
          
          # The backup was successful. To avoid waiting for the pruning, remove the trap and manually run start_stack.
          trap - EXIT
          start_stack

          restic forget --host $RES_HOST --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
        '';
      };
    in mapAttrs' (name: _: nameValuePair (unitName name) {
      description   = "Restic backup of Docker Compose stack ${name}";
      after         = [ "docker.service" ];
      wants         = [ "docker.service" ];
      serviceConfig = {
        Type            = "oneshot";
        User            = "root";
        EnvironmentFile = cfg.resticEnvFile;
        ExecStart       = "${mkBackupScript name}/bin/restic-${name}-backup";
      };
    }) cfg.stacks;
    
    systemd.timers   = filterAttrs (_: v: v != null)
      (mapAttrs' (name: sCfg:
        nameValuePair (unitName name)
          (if sCfg.backupSchedule != null && sCfg.backupSchedule != ""
             then {
               wantedBy    = [ "timers.target" ];
               timerConfig = {
                 OnCalendar = sCfg.backupSchedule;
                 Persistent = true;
               };
             }
             else null)
       ) cfg.stacks);

    environment.systemPackages = let
      mkDockerStack = name: dir: pkgs.stdenv.mkDerivation {
        pname = "docker-manage-stack-${name}";
        version = "1.0";
        src = dir;
        dontPatchShebangs = true; # most stuff is used in docker containers, i'll manually patch the needed shebangs
        installPhase = ''
          mkdir -p $out/${name}
          cp -r . $out/${name}
          patchShebangs $out/${name}/manage.sh
          mkdir -p $out/bin
          ln -s $out/${name}/manage.sh $out/bin/docker-manage-stack-${name}
        '';
      };
    in mapAttrsToList (name: sCfg: mkDockerStack name sCfg.path) cfg.stacks ++ [
      (pkgs.writeShellApplication {
        name          = "restic-docker-stack-restore";
        runtimeInputs = [ pkgs.restic pkgs.docker pkgs.bash pkgs.findutils pkgs.jq pkgs.gum ];
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          usage() { echo "Usage: $(basename "$0") <stack>"; exit 1; }

          [[ $# -eq 1 ]] || usage
          [[ "$1" =~ ^(-h|--help)$ ]] && usage
          STACK_NAME="$1"
          [[ -z "$STACK_NAME" ]] && usage

          #TODO: Source instead of hardcoding here, but the next line gives the error "the SC1091 (info): Not following: /etc/restic/docker-stacks.env was not specified as input (see shellcheck -x)."
          #. "${cfg.resticEnvFile}"
          export RESTIC_REPOSITORY="/backup/docker-stacks"
          export RESTIC_PASSWORD="password"

          readarray -t VOLUMES < <(
            docker volume ls \
              --filter "label=com.docker.compose.project=$STACK_NAME" \
              --format '{{json .}}' \
            | jq -r '.Name'
          )
          
          if ((''${#VOLUMES[@]} == 0)); then
            echo "No volumes for $STACK_NAME, bailing"
            exit 0
          fi
          
          readarray -t MOUNTPOINTS < <(docker volume inspect "''${VOLUMES[@]}" | jq -r '.[].Mountpoint')

          mapfile -t SELECTED_MPS < <(
            printf '%s\n' "''${MOUNTPOINTS[@]}" | \
            gum choose --header="Select mountpoints to include ⤵ " \
                --no-limit | sed '/^$/d'
          )

          (( ''${#SELECTED_MPS[@]} )) || { echo "Nothing chosen, aborting"; exit 0; }

          restic --host docker-"$STACK_NAME" snapshots
          SNAP=$(restic --host "docker-$STACK_NAME" snapshots --json \
            | jq -r 'sort_by(.time) | reverse[] | "\(.short_id)"' \
            | gum choose --header "Choose a snapshot to do a dry-run ⤵ ")

          restore() {
            restic restore "$SNAP" \
              --host "docker-$STACK_NAME" \
              --target / \
              "''${SELECTED_MPS[@]/#/--include=}" \
              --delete \
              "$@"
          }

          restore --no-lock --dry-run -vv | grep -v '^unchanged '

          echo
          echo "Continue with actual restore of mountpoints ''${SELECTED_MPS[*]} from snapshot $SNAP?"
          echo "WARNING: Make sure any docker containers affected are stopped"
          read -rp "[y/N] " REPLY; echo
          [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted"; exit 0; }

          restore

          echo "$STACK_NAME is restored to $SNAP"
        '';
      })
    ];
  });
}
