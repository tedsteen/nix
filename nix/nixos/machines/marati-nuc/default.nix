{ inputs, config, lib, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../modules/base.nix
    ../../modules/docker-stacks.nix
    ../../modules/tailscale-service-host.nix
    ./hardware-configuration.nix
  ];

  nixosBaseConfig.users.ted = {
    fullName = "Ted Steen";
    email = "ted.steen@gmail.com";
    homeStateVersion = "24.11";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
    ];
    extraGroups = [ "docker" ];
    sudoNoPassword = true;
  };

  disko.devices.disk.main.device = "/dev/sda";

  networking.hostName = "marati-nuc";

  time.timeZone = "Europe/Tallinn";

  system.stateVersion = "24.11";

  virtualisation.docker.enable = true;

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
  };

  services.tailscaleServiceHost = {
    enable = true;
    advertiseTags = [ "marati-services-host" ];
    services = {
      "marati-home".target = "http://127.0.0.1:28080";
      "marati-traefik".target = "http://127.0.0.1:28081";
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      cf_dns_api_token = {
        mode = "0440";
        owner = "ted";
        group = "docker";
      };
      tailscale_auth_key = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };

  services.dockerStack = {
    stacks = {
      infra = {
        path = ./docker/infra;
      };
    };
  };
}
