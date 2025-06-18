{ pkgs, dockerUser, ... }: {

  virtualisation.docker.enable = true;

  systemd.services.docker-stack-tedflix-guard = {
    description = "Keep tedflix in sync with mediapool mount";
    path = [ pkgs.bash pkgs.docker pkgs.util-linux ];
    wantedBy = [ "multi-user.target" "mnt-mediapool.mount" ];
    after = [ "docker.service" "mnt-mediapool.mount" ];
    wants = [ "docker.service" "mnt-mediapool.mount" ];
    unitConfig = {
      BindsTo = [ "mnt-mediapool.mount" ]; # service stops if mount goes away
      RequiresMountsFor = [ "/mnt/mediapool" ];
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "tedflix-start-on-remount" ''
        #!${pkgs.bash}/bin/bash
        if mountpoint -q /mnt/mediapool; then
          echo "[+] mediapool mounted, starting the tedflix stack"
          docker compose -p tedflix start
        fi
      '';
      ExecStop = pkgs.writeScript "tedflix-down-on-unmount" ''
        #!${pkgs.bash}/bin/bash
        echo "[+] mediapool unmounted, stopping the tedflix stack"
        docker compose -p tedflix stop
      '';
    };
  };

  # Allow the docker user to run docker
  users.users.${dockerUser}.extraGroups = [ "docker" ];
  # Configure the docker user with shared docker config + some handy scripts
  home-manager.users.${dockerUser} = {
    imports = [
      ../../../../shared/docker-config.nix
    ];
    
    home = let
      mkDockerStack = name: dir: pkgs.stdenv.mkDerivation {
        pname = "docker-stack-${name}";
        version = "1.0";
        src = dir;
        dontPatchShebangs = true; # most stuff is used in docker containers, i'll manually patch the needed shebangs
        installPhase = ''
          mkdir -p $out/${name}
          cp -r . $out/${name}
          patchShebangs $out/${name}/manage.sh
          mkdir -p $out/bin
          ln -s $out/${name}/manage.sh $out/bin/docker-manage-${name}
        '';
      };

      infraStack = mkDockerStack "infra" ./infra;
      automationStack = mkDockerStack "automation" ./automation;
      tedflixStack = mkDockerStack "tedflix" ./tedflix;
      labStack = mkDockerStack "lab" ./lab;
    in {
      packages = [
        (pkgs.writeScriptBin "docker-volumes-backup"
        (builtins.readFile ./scripts/docker-volumes-backup.sh))
        (pkgs.writeScriptBin "docker-volumes-restore"
        (builtins.readFile ./scripts/docker-volumes-restore.sh))

        infraStack
        automationStack
        tedflixStack
        labStack
      ];
    };
  };
}