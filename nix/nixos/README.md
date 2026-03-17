# NixOS

Linux host definitions and helper scripts.

## Layout

- `modules/`: shared Linux baseline and Docker stack helpers
- `machines/`: machine definitions
- `scripts/`: install and apply helpers

## Common Commands

```bash
./nix/nixos/scripts/install-nixos.sh root@<SERVER_IP> "$PWD#pinheiro-nuc"
./nix/nixos/scripts/apply-nixos-config.sh ted@<SERVER_IP> "./#pinheiro-nuc"
./nix/nixos/scripts/apply-nixos-config.sh ted@<SERVER_IP> "./#marati-nuc"
```

`install-nixos.sh` writes hardware configuration to `nix/nixos/machines/<machine>/hardware-configuration.nix` and uses your normal SSH setup.

## Private Web Apps Over Tailscale

`nix/nixos/modules/tailscale-service-host.nix` is intentionally small: it writes the desired Tailscale Services config to `/etc/tailscale/serveconfig.json` and applies it once with a systemd oneshot service. The private apps bind to `127.0.0.1` only, while the public Traefik entrypoint stays internet-facing.

Each machine's `secrets.yaml` must contain an encrypted `tailscale_auth_key`. At boot the built-in NixOS Tailscale module automatically runs `tailscale up` with the machine-specific `extraUpFlags`:

- `pinheiro-nuc`: `--advertise-tags=tag:pinheiro-services-host`
- `marati-nuc`: `--advertise-tags=tag:marati-services-host`

Also make sure:

- MagicDNS and HTTPS are enabled for the tailnet.
- The Tailscale admin console has service definitions matching the names from each machine config, for example `svc:pinheiro-grafana` and `svc:marati-traefik`, typically on `tcp:443`.

Those services will then resolve as `https://<service-name>.<your-tailnet>.ts.net`.
