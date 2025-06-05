{ pkgs, dockerUser, ... }: {

  # Enable docker with buildx support
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker.override (args: { buildxSupport = true; });
  };

  environment.systemPackages = [ pkgs.docker-compose ];

  systemd.services = let
    dockerScripts = ./.;
  in {
    docker-stack-infra = {
      description = "Docker stack: Infra";
      path = [ pkgs.bash pkgs.docker-compose ];
      after = [ "docker.service" ];
      wants = [ "docker.service" ];
      serviceConfig = {
        ExecStart = "${dockerScripts}/infra.sh up";
        ExecStop  = "${dockerScripts}/infra.sh down";
        ExecReload = "${dockerScripts}/infra.sh restart";
        Type="oneshot";
        RemainAfterExit="true";
        WorkingDirectory = "${dockerScripts}";
      };
      wantedBy = [ "multi-user.target" ];
    };

    docker-stack-automation = {
      description = "Docker stack: Automation";
      path = [ pkgs.bash pkgs.docker-compose ];
      after = [ "docker-stack-infra.service" ];
      wants = [ "docker-stack-infra.service" ];
      serviceConfig = {
        ExecStart = "${dockerScripts}/automation.sh up";
        ExecStop  = "${dockerScripts}/automation.sh down";
        ExecReload = "${dockerScripts}/automation.sh restart";
        Type="oneshot";
        RemainAfterExit="true";
        WorkingDirectory = "${dockerScripts}";
      };
      wantedBy = [ "multi-user.target" ];
    };

    docker-stack-lab = {
      description = "Docker stack: Lab";
      path = [ pkgs.bash pkgs.docker-compose ];
      after = [ "docker-stack-infra.service" ];
      wants = [ "docker-stack-infra.service" ];
      serviceConfig = {
        ExecStart = "${dockerScripts}/lab.sh up";
        ExecStop  = "${dockerScripts}/lab.sh down";
        ExecReload = "${dockerScripts}/lab.sh restart";
        Type="oneshot";
        RemainAfterExit="true";
        WorkingDirectory = "${dockerScripts}";
      };
      wantedBy = [ "multi-user.target" ];
    };

    docker-stack-tedflix = {
      description = "Docker stack: Tedflix";
      path = [ pkgs.bash pkgs.docker-compose ];
      # Docker will bind mount into the mediapool and thus depends on it
      after = [ "docker-stack-infra.service" "mnt-mediapool.mount" ];
      wants = [ "docker-stack-infra.service" ];
      unitConfig = {
        RequiresMountsFor = [ "/mnt/mediapool" ];
        BindsTo = [ "mnt-mediapool.mount" ];
      };
      serviceConfig = {
        ExecStart = "${dockerScripts}/tedflix.sh up";
        ExecStop  = "${dockerScripts}/tedflix.sh down";
        ExecReload = "${dockerScripts}/tedflix.sh restart";
        Type="oneshot";
        RemainAfterExit="true";
        WorkingDirectory = "${dockerScripts}";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  # TODO: # Perhaps needed for transmissions wireguard tunnel to work?
  # networking.sysctl = {
  #   "net.ipv4.conf.all.src_valid_mark" = 1;
  # };

  # Let docker expose port 80 and 81 for traefik (internal and external services are exposed on 80 and 81)
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;
  networking.firewall.allowedTCPPorts = [ 80 81 ];

  # Allow the docker user to run docker
  users.users.${dockerUser}.extraGroups = [ "docker" ];
  # Configure the docker user with shared docker config + some handy scripts
  home-manager.users.${dockerUser} = {
    imports = [
      ../../../../shared/docker-config.nix
    ];
    
    home = {
      packages = [
        (pkgs.writeScriptBin "docker-volumes-backup"
        (builtins.readFile ./scripts/docker-volumes-backup.sh))
        (pkgs.writeScriptBin "docker-volumes-restore"
        (builtins.readFile ./scripts/docker-volumes-restore.sh))
      ];
    };
  };
}