# Backup

A systemd service `backup-pinheiro` runs nightly at 02:30 and backs up all Docker
services to Google Drive using restic + rclone.

## Setup

You just need to fill in three secrets:

```sh
sops nix/nixos/machines/pinheiro-nuc/secrets.yaml
```

Add these keys with their values:

| Key | Value |
|-----|-------|
| `restic_password` | A strong password for the restic repository |
| `home_assistant_token` | A long-lived access token from HA: Settings → System → Long-Lived Access Tokens |
| `rclone_config` | An rclone config file with a `gdrive` remote configured for Google Drive |

### Getting the rclone config

On a machine where you can run the Google Drive OAuth flow (your laptop, not the server):

```sh
rclone config
# Create a new remote named "gdrive" with Google Drive scope
# After it's configured, the config is at ~/.config/rclone/rclone.conf
# Copy the entire file content and paste it as the sops value for rclone_config
```

Then deploy the Nix config. That's it — everything else is automated.

## What's backed up

See `default.nix` → `systemd.services.backup-pinheiro` for the full list.

## Restore

```sh
sudo RESTIC_PASSWORD_FILE=/run/secrets/restic_password \
    RCLONE_CONFIG=/run/secrets/rclone_config \
    restic -r rclone:gdrive:pinheiro-backup snapshots

sudo RESTIC_PASSWORD_FILE=/run/secrets/restic_password \
    RCLONE_CONFIG=/run/secrets/rclone_config \
    restic -r rclone:gdrive:pinheiro-backup restore latest --target /tmp/restore
```
