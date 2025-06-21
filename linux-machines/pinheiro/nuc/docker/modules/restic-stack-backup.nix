{ config, lib, pkgs, ... }:
with lib;
{
  options.services.resticDockerStackBackup = {
    envFile = mkOption {
      type        = types.path;
      description = "File with RESTIC_* vars shared by every job.";
    };

    stacks = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options.schedule = mkOption {
          type        = types.nullOr types.str;   # null ⇒ no timer
          default     = null;
          description = "systemd OnCalendar spec (null for manual-only).";
        };
      }));
      default     = {};
      description = "Compose stacks to back up, keyed by stack name.";
    };
  };

  config = let
    cfg = config.services.resticDockerStackBackup;
  in mkIf (cfg.stacks != {}) (let
    # local helpers (never escape this let, so no global weirdness)
    unitName   = name: "restic-backup-${name}";

    makeScript = name: pkgs.writeShellApplication {
      name = "restic-${name}-backup";
      runtimeInputs = [ pkgs.restic pkgs.docker pkgs.bash ];
      text = ''
        set -euo pipefail
        STACK_NAME=${name}

        if ! restic snapshots &>/dev/null; then
          echo "initialising repo @ $RESTIC_REPOSITORY"
          restic init
        fi

        mapfile -t VOLUMES < <(docker volume ls --filter label=com.docker.compose.project=$STACK_NAME -q)
        [[ "''${#VOLUMES[@]}" -eq 0 ]] && {
          echo "no vols for $STACK_NAME, bailing"; exit 0; }

        mapfile -t MOUNTPOINTS < <(docker volume inspect -f '{{ .Mountpoint }}' "''${VOLUMES[@]}")

        echo "stopping stack $STACK_NAME"
        docker compose -p "$STACK_NAME" stop || true
        trap 'docker compose -p "$STACK_NAME" start || echo "Failed to restart!"' EXIT

        restic backup "''${MOUNTPOINTS[@]}" \
          --host "docker-$STACK_NAME" \
          --tag stack --tag "$STACK_NAME"

        restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
      '';
    };

    serviceFor = name: {
      description   = "Restic backup of Docker Compose stack ${name}";
      after         = [ "docker.service" ];
      wants         = [ "docker.service" ];
      serviceConfig = {
        Type            = "oneshot";
        User            = "root";
        EnvironmentFile = cfg.envFile;
        ExecStart       = "${makeScript name}/bin/restic-${name}-backup";
      };
    };

    timerFor = schedule: {
      wantedBy    = [ "timers.target" ];
      timerConfig = {
        OnCalendar = schedule;
        Persistent = true;
      };
    };

    services = mapAttrs' (name: _: nameValuePair (unitName name) (serviceFor name))
                cfg.stacks;

    timers   = filterAttrs (_: v: v != null)
                (mapAttrs' (name: sCfg:
                  nameValuePair (unitName name)
                    (if sCfg.schedule != null && sCfg.schedule != ""
                       then timerFor sCfg.schedule
                       else null)
                 ) cfg.stacks);
  in {
    systemd.services = services;
    systemd.timers   = timers;
  });
}
