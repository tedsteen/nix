#!/bin/sh
export HOSTNAME=${1:-"nixos"}
export TIMEZONE=${2:-"Europe/Lisbon"}

sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart root ext4 512MB -8GB
sudo parted /dev/sda -- mkpart swap linux-swap -8GB 100%

sudo parted /dev/sda -- mkpart ESP fat32 1MB 512MB
sudo parted /dev/sda -- set 3 esp on

sudo mkfs.ext4 -L nixos /dev/sda1
sudo mkswap -L swap /dev/sda2

sudo mkfs.fat -F 32 -n boot /dev/sda3

sudo mount /dev/disk/by-label/nixos /mnt

sudo mkdir -p /mnt/boot
sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

sudo swapon /dev/sda2

sudo nixos-generate-config --root /mnt

CONFIGURATION=$(cat <<EOF
{ config, lib, pkgs, ... }:
let
  nixRepo = builtins.fetchGit {
    url = "https://github.com/tedsteen/nix";
    ref = "master";
  };
in {
  imports = [
    ./hardware-configuration.nix
    "\${nixRepo}/common.nix"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "$TIMEZONE";

  networking.hostName = "$HOSTNAME";
  system = {
    copySystemConfiguration = true;
    stateVersion = "24.11"; # DON'T CHANGE THIS UNLESS YOU KNOW WHAT YOU'RE DOING
  };
}
EOF
)
echo "$CONFIGURATION" | sudo tee /mnt/etc/nixos/configuration.nix > /dev/null

sudo nixos-install
sudo reboot