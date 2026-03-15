{ lib, ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/docker-stacks.nix
    ./hardware-configuration.nix
  ];

  ted.nixos = {
    disk.device = "/dev/sda";
    hostName = "marati-nuc";
    timeZone = "Europe/Tallinn";
    stateVersion = "24.11";
  };

  users.users.ted.extraGroups = lib.mkAfter [ "docker" ];

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
