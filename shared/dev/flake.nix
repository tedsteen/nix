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
      default = 
      let
        profiles = builtins.filter (s: s != "") (pkgs.lib.splitString " " (builtins.getEnv "PROFILES"));
        has = n: pkgs.lib.elem n profiles;
      in pkgs.mkShell {
        packages = with pkgs; [
            # General stuff
            pkg-config
            cmake
          ]
          ++ lib.optionals (has "rust") [
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rustfmt" "clippy" "rust-analyzer" ];
              targets = lib.optionals (has "esp") [ "riscv32imc-unknown-none-elf" ];
            })
          ]
          ++ lib.optionals (has "node") [
            nodejs
            pnpm
            yarn
          ]
          ++ lib.optionals (has "esp")  [
            espflash
          ]
          ++ lib.optionals (has "python")  [
            python3
          ]
          ++ lib.optionals (has "nes")  [
            cc65
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
