{
  description = "Dev environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
  let
    lib = nixpkgs.lib;
    systems = [
      "aarch64-darwin" "x86_64-darwin"
      "x86_64-linux"   "aarch64-linux"
    ];
    forAllSystems = f: lib.genAttrs systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
      in f pkgs
    );
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          # General
          pkg-config
          cmake

          # Rust
          (rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" "rustfmt" "clippy" "rust-analyzer" ];
            targets = [ "riscv32imc-unknown-none-elf" ];
          })

          # ESP32
          espflash

          # Node
          nodejs
          pnpm
          yarn

          # NES
          cc65
          python3
        ];

        # Only on macOS
        buildInputs = lib.optionals pkgs.stdenv.isDarwin [ pkgs.apple-sdk_15 ];

        shellHook = ''
          export CC=clang
          export CXX=clang++

          if [[ "$(uname)" = "Darwin" ]]; then
            export MACOSX_DEPLOYMENT_TARGET=14
          fi

          echo "Dev environment!"
          zsh
          exit
        '';
      };
    });
  };
}
