{
  description = "Dev environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
  let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ (import rust-overlay) ];
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        # General stuff
        pkg-config
        cmake

        # Rust
        (rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rustfmt" "clippy" "rust-analyzer" ];
          targets = [ "riscv32imc-unknown-none-elf" ];
        })
        #TODO: gdb?

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

      buildInputs = with pkgs; [
        apple-sdk_15
      ];

      shellHook = ''
        export CC="clang"
        export CXX="clang++"
        export MACOSX_DEPLOYMENT_TARGET="14"
        echo "Dev environment!"
        zsh
        exit
      '';
    };
  };
}