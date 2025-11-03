{
  description = "Dev environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, zig, ... }:
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
        zigPkg = zig.packages.${system}.default;
      in f pkgs zigPkg
    );
  in {
    devShells = forAllSystems (pkgs: zigPkg: {
      default = 
      let
        profiles = lib.filter (s: s != "") (lib.splitString " " (builtins.getEnv "PROFILES"));
        has = name: lib.elem name profiles;
      in pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
            # General stuff
            pkg-config
            cmake
          ]
          # TODO: A special config for extensia on rust (havent figured out how to use espup with the oxalica overlay)
          ++ lib.optionals (has "rust-extensia") [
            rustup
            espup # For targets not yet available in rust (like the esp32s3 xtensa cpu)
            probe-rs
          ]
          ++ lib.optionals (has "rust") [
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rustfmt" "clippy" "rust-analyzer" ];
              targets = lib.optionals (has "embedded") [ "riscv32imc-unknown-none-elf" "thumbv7em-none-eabi" ];
            })
            # cargo-generate
          ]
          ++ lib.optionals (has "node") [
            nodejs
            corepack
          ]
          ++ lib.optionals (has "embedded")  [
            # espflash
            probe-rs

          ]
          ++ lib.optionals (has "python")  [
            python3
          ]
          ++ lib.optionals (has "nes")  [
            cc65
          ]
          ++ lib.optionals (has "zig") [
            zigPkg
          ];
        
        # Only on macOS
        # TODO: Check if this is needed
        buildInputs = lib.optionals pkgs.stdenv.isDarwin [ pkgs.apple-sdk_14 ];

        shellHook = ''
          export CC=clang
          export CXX=clang++

          if [[ "$(uname)" = "Darwin" ]]; then
            export MACOSX_DEPLOYMENT_TARGET=14
          fi

          echo "Dev environment (${lib.strings.concatStringsSep ", " profiles})"
        '' + lib.optionalString (has "rust-extensia") ''
          . ~/export-esp.sh
        '';
      };
    });
  };
}
