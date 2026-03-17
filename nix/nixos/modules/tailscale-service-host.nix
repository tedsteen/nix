{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tailscaleServiceHost;
  tailscale = lib.getExe config.services.tailscale.package;
  jq = lib.getExe pkgs.jq;
  suggestedUpCommand =
    concatStringsSep " " (
      [ tailscale "up" "--advertise-tags=${concatStringsSep "," (map (t: "tag:${t}") cfg.advertiseTags)}" ]
    );

  advertisedServices =
    mapAttrsToList
      (_: service: "svc:${service.serviceName}")
      cfg.services;

  serveConfigFile = pkgs.writeText "tailscale-serveconfig.json" (builtins.toJSON {
    version = "0.0.1";
    services = mapAttrs'
      (_: service:
        nameValuePair "svc:${service.serviceName}" {
          endpoints = {
            "${service.endpoint}" = service.target;
          };
        })
      cfg.services;
  });

in
{
  options.services.tailscaleServiceHost = {
    enable = mkEnableOption "reconciling host-local backends into Tailscale Services";

    advertiseTags = mkOption {
      type = types.listOf types.str;
      description = "Tailscale tags to advertise (without the 'tag:' prefix).";
    };

    services = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          serviceName = mkOption {
            type = types.str;
            default = name;
            description = "Tailscale service name without the `svc:` prefix.";
          };

          endpoint = mkOption {
            type = types.str;
            default = "tcp:443";
            example = "tcp:5432";
            description = "Advertised Tailscale service endpoint.";
          };

          target = mkOption {
            type = types.str;
            example = "http://127.0.0.1:8080";
            description = "Host-local destination that receives traffic for this service.";
          };
        };
      }));
      default = { };
      description = "Host-local services to advertise through Tailscale Services.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "services.tailscaleServiceHost requires services.tailscale.enable = true;";
      }
    ];

    services.tailscale.extraUpFlags = [ "--advertise-tags=${concatStringsSep "," (map (t: "tag:${t}") cfg.advertiseTags)}" ];

    environment.etc."tailscale/serveconfig.json".source = serveConfigFile;

    systemd.services.tailscale-service-host-reconcile = {
      description = "Reconcile Tailscale Services advertised from host-local backends";
      after = [ "network-online.target" "tailscaled.service" "tailscaled-autoconnect.service" ];
      wants = [ "network-online.target" "tailscaled.service" "tailscaled-autoconnect.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ serveConfigFile ];
      path = [ pkgs.jq config.services.tailscale.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        let
          advertisedServicesArgs = escapeShellArgs advertisedServices;
        in
        ''
          set -euo pipefail

          status_json="$(${tailscale} status --json 2>/dev/null || true)"
          backend_state="$(printf '%s' "$status_json" | ${jq} -r '.BackendState // empty')"

          if [ "$backend_state" != "Running" ]; then
            echo "tailscale backend state is ''${backend_state:-unknown}; skipping service reconciliation"
            echo "log in first with: ${suggestedUpCommand}"
            exit 0
          fi

          tag_count="$(printf '%s' "$status_json" | ${jq} '(.Self.Tags // []) | length')"
          if [ "$tag_count" -eq 0 ]; then
            echo "tailscale host is not using a tag-based identity; skipping service reconciliation"
            echo "log in first with: ${suggestedUpCommand}"
            exit 0
          fi

          if ! ${tailscale} serve set-config --all /etc/tailscale/serveconfig.json; then
            echo "failed to apply /etc/tailscale/serveconfig.json; check Tailscale Services setup in the admin console"
            exit 0
          fi

          for service in ${advertisedServicesArgs}; do
            if ! ${tailscale} serve advertise "$service"; then
              echo "failed to advertise $service; check Service definitions and auto-approvers in Tailscale"
              exit 0
            fi
          done
        '';
    };
  };
}
