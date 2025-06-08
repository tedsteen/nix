{ pkgs, dockerUser, ... }: let
  mkDockerStack = name: dir: pkgs.stdenv.mkDerivation {
    pname = "docker-stack-${name}";
    version = "1.0";
    src = dir;
    installPhase = ''
      mkdir -p $out/${name}
      cp -r . $out/${name}
      mkdir -p $out/bin
      ln -s $out/${name}/manage.sh $out/bin/docker-manage-${name}
    '';
  };

  tedflixStack = mkDockerStack "tedflix" ./tedflix;  
in {
  # Enable docker with buildx support
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker.override (args: { buildxSupport = true; });
  };

  systemd.services.docker-stack-tedflix-guard = {
    description = "Keep tedflix in sync with mediapool mount";
    path = [ pkgs.bash pkgs.docker pkgs.util-linux tedflixStack ];
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
      ExecStart = pkgs.writeScript "tedflix-up-on-remount" ''
        #!${pkgs.bash}/bin/bash
        if mountpoint -q /mnt/mediapool; then
          echo "[+] mediapool mounted, bringing tedflix stack up"
          docker-manage-tedflix up
        fi
      '';
      ExecStop = pkgs.writeScript "tedflix-down-on-unmount" ''
        #!${pkgs.bash}/bin/bash
        echo "[+] mediapool unmounted, bringing tedflix stack down"
        docker-manage-tedflix down
      '';
    };
  };

  # Let docker expose port 80, 81 and 443 for traefik. Internal and external (http + https) services are exposed on those ports.
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;
  networking.firewall.allowedTCPPorts = [ 80 81 443 ];

  # Allow the docker user to run docker
  users.users.${dockerUser}.extraGroups = [ "docker" ];
  # Configure the docker user with shared docker config + some handy scripts
  home-manager.users.${dockerUser} = {
    imports = [
      ../../../../shared/docker-config.nix
    ];
    
    home = let
      automationStack = mkDockerStack "automation" ./automation;
      infraStack = mkDockerStack "infra" ./infra;
      labStack = mkDockerStack "lab" ./lab;
    in {
      packages = [
        (pkgs.writeScriptBin "docker-volumes-backup"
        (builtins.readFile ./scripts/docker-volumes-backup.sh))
        (pkgs.writeScriptBin "docker-volumes-restore"
        (builtins.readFile ./scripts/docker-volumes-restore.sh))

        automationStack
        infraStack
        labStack
        tedflixStack
      ];
    };
  };
}