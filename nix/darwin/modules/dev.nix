{ config, inputs, lib, pkgs, ... }:

let
  username = config.macBaseConfig.user.username;
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rustfmt" "clippy" "rust-analyzer" ];
    targets = [
      "riscv32imc-unknown-none-elf"
      "thumbv7em-none-eabi"
    ];
  };
in
{
  nixpkgs.overlays = [
    inputs.rust-overlay.overlays.default
  ];

  environment.variables = {
    CC = lib.mkDefault "clang";
    CXX = lib.mkDefault "clang++";
    MACOSX_DEPLOYMENT_TARGET = lib.mkDefault "14";
  };

  home-manager.users.${username}.home.packages = with pkgs; [
    pkg-config
    cmake
    ccache

    rustToolchain
    espup
    probe-rs-tools

    nodejs_24
    (corepack.override { nodejs = nodejs_24; })
    python3
    cc65
    zig
    go
  ];
}
