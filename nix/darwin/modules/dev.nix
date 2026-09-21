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
  #
  # A session's tools keep their caches where the file sandbox can write. Nix's
  # fetcher cache, wrangler's log, and npm's cache all default outside the
  # workspace (~/.cache/nix, ~/Library/Preferences/.wrangler, ~/.npm), where
  # they fail with EPERM and turn a nix command, a direct wrangler call, or any
  # npm command that writes its cache into an error. /tmp is writable but does
  # not survive a reboot, so each is refilled once per boot. npm's is set inside
  # the session only, so the npx that starts dsh keeps using the real ~/.npm; it
  # has to be assigned, not defaulted, because that npx exports its own
  # npm_config_cache into everything it starts.
  deepseek-harness = pkgs.writeShellScriptBin "dsh" ''
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-/tmp/dsh-cache}"
    export WRANGLER_LOG_PATH="''${WRANGLER_LOG_PATH:-/tmp/dsh-wrangler}"
    exec ${pkgs.nodejs_26}/bin/npx --yes -p @deepseek-ai/dsh -- \
      sh -c 'export npm_config_cache="''${DSH_NPM_CACHE:-/tmp/dsh-npm}"; exec node --expose-internals "$(command -v dsh)" "$@"' dsh "$@"
  '';

  # Pi coding harness via npx, so `pi` always resolves the newest published
  # release instead of the version pinned in nixpkgs (26.05 ships 0.75.4 while
  # npm is on 0.85.x). `@latest` is explicit so npx re-checks the registry even
  # when it already holds a cached copy. ripgrep/fd mirror the PATH the nixpkgs
  # package wraps in for pi's grep/find tools.
  pi-harness = pkgs.writeShellScriptBin "pi" ''
    export PATH="${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}:$PATH"
    export PI_SKIP_VERSION_CHECK="''${PI_SKIP_VERSION_CHECK:-1}"
    exec ${pkgs.nodejs_26}/bin/npx --yes --ignore-scripts \
      -p @earendil-works/pi-coding-agent@latest pi "$@"
  '';
  # eas-cli from the published npm package. nixpkgs' copy is 20.4.0 and this
  # app requires >= 24.0.0 (eas.json), so build it here instead: the published
  # build/ is already compiled, so only its dependencies are installed. The
  # lock beside this file is generated from the same package with the
  # monorepo's scripts and devDependencies removed.
  eas-cli = pkgs.buildNpmPackage rec {
    pname = "eas-cli";
    version = "24.7.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/eas-cli/-/eas-cli-${version}.tgz";
      hash = "sha256-UL+ERRfF0CL+/pRj8BoabcN/Usdl3hiVJFo+GWZtLoE=";
    };
    postPatch = ''
      ${pkgs.jq}/bin/jq 'del(.devDependencies, .scripts)' package.json > package.json.tmp
      mv package.json.tmp package.json
      cp ${./eas-cli-package-lock.json} package-lock.json
    '';
    npmDepsHash = "sha256-9bEXj5aIGXpCN0YY+3Dr9jgpmVG14PxeagiVbcgJNCw=";
    dontNpmBuild = true;
    npmInstallFlags = [ "--omit=dev" ];
    meta = {
      description = "EAS command line tool";
      homepage = "https://github.com/expo/eas-cli";
      license = pkgs.lib.licenses.mit;
      mainProgram = "eas";
    };
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

  # DeepSeek API key, stored once and encrypted in nix/darwin/secrets.yaml.
  # Both Macs are sops recipients (see nix/darwin/.sops.yaml); each host decrypts
  # with its own ssh key. sops-nix skips key paths it cannot read, so listing an
  # extra candidate is harmless and covers hosts where ~/.ssh/random is the key.
  # On darwin there is no services.openssh.hostKeys, so the default key source is
  # empty and sops.age.sshKeyPaths has to be set explicitly.
  sops.age.sshKeyPaths = [
    "/Users/${username}/.ssh/id_ed25519"
    "/Users/${username}/.ssh/random"
  ];

  sops.secrets.deepseek_api_key = {
    owner = username;
    mode = "0400";
  };

  home-manager.users.${username} = {
    home.packages = with pkgs; [
      pkg-config
      cmake
      ccache
      coreutils

      rustToolchain
      espup
      probe-rs-tools

      nodejs_26
      (corepack.override { nodejs-slim = nodejs-slim_26; })
      watchman
      python3
      cocoapods
      cc65
      zig
      go

      deepseek-harness
      pi-harness
      eas-cli
    ];

    # DeepSeek V4.1 Flash (API id `deepseek-flash`) plus the pi defaults that go
    # with it. Kept as real files rather than inline JSON so they stay readable
    # and diffable. They land in the store as read-only symlinks: pi reads them
    # fine, but its interactive Ctrl+S "save startup default" write will fail,
    # so change defaults here instead.
    home.file = {
      ".pi/agent/models.json".source = ./pi/models.json;
      ".pi/agent/settings.json".source = ./pi/settings.json;
    };

    # pi's built-in `deepseek` provider reads DEEPSEEK_API_KEY. Read the secret
    # at shell start rather than baking the key into the store; guarded so a
    # shell still starts if the secret has not been activated yet.
    home.sessionVariablesExtra = ''
      if [ -r "${config.sops.secrets.deepseek_api_key.path}" ]; then
        export DEEPSEEK_API_KEY="$(cat ${config.sops.secrets.deepseek_api_key.path})"
      fi
    '';
  };
}
