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
  # DeepSeek Harness via npx. nixpkgs' node is rejected by the
  # node-addon-require-builtin hack dsh uses to reach Node internals, so run
  # the entrypoint with --expose-internals instead of the plain `dsh` bin.
  deepseek-harness = pkgs.writeShellScriptBin "dsh" ''
    exec ${pkgs.nodejs_24}/bin/npx --yes -p @deepseek-ai/dsh -- \
      sh -c 'exec node --expose-internals "$(command -v dsh)" "$@"' dsh "$@"
  '';
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
    watchman
    python3
    cocoapods
    cc65
    zig
    go

    deepseek-harness
  ];
}
