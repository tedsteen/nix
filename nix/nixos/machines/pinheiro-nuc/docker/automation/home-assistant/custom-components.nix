{ pkgs, lib }:
let
  inherit (lib) mapAttrsToList concatStringsSep;
in rec {
  fetchGitHub = args: pkgs.fetchFromGitHub args;

  buildComponents = components: pkgs.runCommand "ha-custom-components" { } ''
    mkdir -p "$out"
    ${concatStringsSep "\n" (mapAttrsToList (domain: src: ''
      cp -rL ${src}/custom_components/${domain} "$out/"
    '') components)}
  '';
}
