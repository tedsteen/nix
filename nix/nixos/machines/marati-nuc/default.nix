{ inputs, config, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../modules/base.nix
    ../../modules/docker-stacks.nix
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

  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
  };
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  time.timeZone = "Europe/Tallinn";

  system.stateVersion = "24.11";

  virtualisation.docker.enable = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      cf_dns_api_token = {
        mode = "0440";
        owner = "ted";
        group = "docker";
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
