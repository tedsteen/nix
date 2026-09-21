# Darwin

nix-darwin configurations for my Macs.

## Machines

- `teds-mbp`
- `steen-imac`

## Apply

```bash
sudo ./update_mac.sh
```

## Shared Modules

- [modules/base.nix](./modules/base.nix): shared macOS baseline
- [modules/dev.nix](./modules/dev.nix): dev toolchain plus the `dsh` and `pi` coding harnesses
- [modules/pi/](./modules/pi): declarative `~/.pi/agent` config for the pi harness

## Pi coding harness

`pi` is installed as an npx wrapper in [modules/dev.nix](./modules/dev.nix) so it
always runs the newest published `@earendil-works/pi-coding-agent` release
(nixpkgs 26.05 lags several releases behind). It is configured for
**DeepSeek V4.1 Flash** (API model id `deepseek-flash`) in
[modules/pi/models.json](./modules/pi/models.json):

- 1M context, 384K max output, native image input, DeepSeek thinking format
- thinking levels exposed as `off` / `low` / `high` / `max`; `minimal` and
  `medium` clamp up to DeepSeek's real tiers and `xhigh` reaches `max`
- `temperature 1.0`, `top_p 0.95` — the sampling DeepSeek used for its own agent
  benchmarks (`temperature` is ignored while thinking is enabled)

`DEEPSEEK_API_KEY` is read from the sops secret `deepseek_api_key`. That key must
exist in `secrets.yaml` **before** the next switch, otherwise activation fails:

```bash
sops nix/darwin/secrets.yaml          # add: deepseek_api_key: sk-...
# or, without putting the key in shell history:
printf '%s' 'sk-...' | sops set --value-stdin nix/darwin/secrets.yaml '["deepseek_api_key"]'
```

Then apply and check:

```bash
sudo ./update_mac.sh
pi --list-models          # expects deepseek/deepseek-flash
```

Both Macs are already sops recipients in [.sops.yaml](./.sops.yaml); each host
decrypts with its own `~/.ssh/id_ed25519` (see `sops.age.sshKeyPaths` in
`modules/dev.nix`).

Because `~/.pi/agent/{models,settings}.json` are home-manager symlinks into the
nix store, pi's interactive Ctrl+S "save startup default" cannot write them —
change defaults in [modules/pi/](./modules/pi) instead.
