{ ... }:
let
  me = {
    fullName = "Ted Steen";
    email = "ted.steen@gmail.com";
    homeStateVersion = "24.11";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeAaaHvF/6KmN2neKxeHyL0WEuVC5XIp0CHp1i3u6Ff ted@mbp-2025-05-04"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp8j7ztDOXAovDvPh6OaIoWWnHmr8n63/wdh11AvtZo ted@imac-2025-05-07"
    ];
    sudoNoPassword = true;
  };
in
{
  imports = [
    ../../modules/base.nix
    ./hardware-configuration.nix
  ];

  nixosBaseConfig.users.ted = me;

  disko.devices.disk.main.device = "/dev/vda";

  networking.hostName = "lab";

  time.timeZone = "Europe/Lisbon";

  system.stateVersion = "24.11";
}
