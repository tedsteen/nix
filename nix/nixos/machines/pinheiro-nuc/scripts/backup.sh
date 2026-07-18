set -euo pipefail

STAGING="/var/backups/staging"
RESTIC_REPO="b2:pinheiro-backup:"
export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/run/secrets/restic_password}"
export B2_ACCOUNT_ID="${B2_ACCOUNT_ID:-}"
export B2_ACCOUNT_KEY="${B2_ACCOUNT_KEY:-}"
HA_TOKEN="${HA_TOKEN:-/run/secrets/home_assistant_token}"

mkdir -p "$STAGING"
NOW=$(date +%Y%m%d-%H%M%S)
LOG="/var/log/backup.log"
exec > "$LOG" 2>&1

echo "[$NOW] === Starting backup ==="

# ─── Home Assistant ──────────────────────────────────
if [ -f "$HA_TOKEN" ]; then
  TOKEN=$(cat "$HA_TOKEN")
  echo "Triggering HA backup..."
  curl -s -X POST http://localhost:18123/api/services/backup/create \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}' > /dev/null || echo "  HA backup failed"
fi

# ─── MariaDB (lab) ───────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q 'lab-moobeldaja-db-1'; then
  echo "Dumping lab MariaDB..."
  mkdir -p "$STAGING/mariadb"
  docker exec -e MYSQL_PWD="$(cat /run/secrets/moobeldaja_db_password)" lab-moobeldaja-db-1 \
    mariadb-dump --single-transaction --quick --user=wordpress wordpress \
    | gzip > "$STAGING/mariadb/lab-moobeldaja-db-1-$NOW.sql.gz" || echo "  MariaDB dump failed"
fi

# ─── *Arr auto-backups ───────────────────────────────
for arr in radarr sonarr prowlarr; do
  container="tedflix-$arr-1"
  if docker ps --format '{{.Names}}' | grep -q "$container"; then
    echo "Copying $arr Backups..."
    docker cp "$container:/config/Backups/." "$STAGING/$arr/" 2>/dev/null || true
  fi
done

# ─── Bazarr (lowercase /config/backup/) ─────────────
if docker ps --format '{{.Names}}' | grep -q 'tedflix-bazarr-1'; then
  echo "Copying Bazarr backup..."
  docker cp tedflix-bazarr-1:/config/backup/. "$STAGING/bazarr/" 2>/dev/null || true
fi

# ─── Seerr (Overseerr) — SQLite online backup ────────
seerr_vol="/var/lib/docker/volumes/tedflix_seerr_config/_data"
if [ -d "$seerr_vol" ]; then
  echo "Backing up Seerr database..."
  mkdir -p "$STAGING/seerr"
  sqlite3 "$seerr_vol/db/db.sqlite3" ".backup $STAGING/seerr/db.sqlite3" 2>/dev/null || true
  cp "$seerr_vol/settings.json" "$STAGING/seerr/" 2>/dev/null || true
  echo "  Seerr: $(du -sh $STAGING/seerr | cut -f1)"
fi

# ─── Plex (library DB + preferences only) ───────────
plex_vol="/var/lib/docker/volumes/tedflix_plex_config/_data/Library/Application Support/Plex Media Server"
if [ -d "$plex_vol" ]; then
  echo "Backing up Plex library DB and preferences..."
  mkdir -p "$STAGING/plex"
  db="$plex_vol/Plug-in Support/Databases/com.plexapp.plugins.library.db"
  if [ -f "$db" ]; then
    sqlite3 "$db" ".backup $STAGING/plex/com.plexapp.plugins.library.db" 2>/dev/null || true
  fi
  cp "$plex_vol/Preferences.xml" "$STAGING/plex/" 2>/dev/null || true
  echo "  Plex critical: $(du -sh $STAGING/plex | cut -f1)"
fi

# ─── Minecraft world ─────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q 'lab-minecraft'; then
  echo "Backing up Minecraft world..."
  docker exec lab-minecraft-1 rcon-cli save-all flush 2>/dev/null || true
  sleep 2
  volpath="/var/lib/docker/volumes/lab_minecraft_data/_data"
  if [ -d "$volpath" ]; then
    mkdir -p "$STAGING/minecraft"
    sudo tar czf "$STAGING/minecraft/world.tar.gz" -C "$volpath" . 2>/dev/null || true
    echo "  Minecraft size: $(du -sh $STAGING/minecraft | cut -f1)"
  fi
fi

# ─── Docker volume data dirs (configs) ──────────────
echo "Backing up config volumes..."
mkdir -p "$STAGING/volumes"
for vol in infra_grafana infra_traefik_letsencrypt \
            automation_mosquitto_data automation_nodered_data \
            tedflix_transmission_config otel-lgtm-data infra_otel_lgtm \
            lab_moobeldaja_wordpress; do
  volpath="/var/lib/docker/volumes/$vol/_data"
  if [ -d "$volpath" ]; then
    mkdir -p "$STAGING/volumes/$vol"
    cp -a "$volpath/." "$STAGING/volumes/$vol/" 2>/dev/null || true
    echo "  $vol: $(du -sh $volpath | cut -f1)"
  fi
done

# ─── Init restic if first run ───────────────────────
if ! restic -r "$RESTIC_REPO" snapshots 2>/dev/null 1>&2; then
  echo "Initialising restic repository..."
  restic -r "$RESTIC_REPO" init
fi

# ─── Run restic ─────────────────────────────────────
echo "Running restic backup..."
restic -r "$RESTIC_REPO" backup "$STAGING" \
  --tag "pinheiro" --tag "nightly" --verbose \
  --limit-upload 500 --stuck-request-timeout 5m

echo "[$(date +%Y%m%d-%H%M%S)] === Backup complete ==="
echo "Staging size: $(du -sh $STAGING | cut -f1)"
rm -rf "$STAGING"/*

# ─── Prune old snapshots ────────────────────────────
echo "Pruning old snapshots..."
restic -r "$RESTIC_REPO" forget \
  --keep-daily 7 --keep-weekly 2 --keep-monthly 1 \
  --prune
