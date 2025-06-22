{ config, lib, pkgs, ... }:
with lib;
{
  options.services.dockerStack = {
    resticEnvFile = mkOption {
      type        = types.path;
      description = "File with RESTIC_* vars shared by every job.";
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
        runtimeInputs = [ pkgs.restic pkgs.docker pkgs.bash ];
        text = ''
          set -euo pipefail
          STACK_NAME=${name}

          if ! restic snapshots &>/dev/null; then
            echo "Initialising repo @ $RESTIC_REPOSITORY"
            restic init
          fi

          mapfile -t VOLUMES < <(docker volume ls --filter label=com.docker.compose.project=$STACK_NAME -q)
          [[ "''${#VOLUMES[@]}" -eq 0 ]] && {
            echo "no vols for $STACK_NAME, bailing"; exit 0; }

          mapfile -t MOUNTPOINTS < <(docker volume inspect -f '{{ .Mountpoint }}' "''${VOLUMES[@]}")

          echo "Stopping stack $STACK_NAME"
          docker compose -p "$STACK_NAME" stop || true
          trap 'docker compose -p "$STACK_NAME" start || echo "Failed to restart!"' EXIT

          restic backup "''${MOUNTPOINTS[@]}" \
            --host "docker-$STACK_NAME" \
            --tag stack --tag "$STACK_NAME"

          restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
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
    in mapAttrsToList (name: sCfg: mkDockerStack name sCfg.path) cfg.stacks;
  });
}
