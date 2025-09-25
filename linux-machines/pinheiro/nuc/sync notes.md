## Sync the media
```bash
rsync -avP --delete --hard-links --no-compress -e "ssh" /var/lib/stuff/tedflix/ ted@pinheiro.s3n.io:/mnt/mediapool/tedflix/

# Fix the owners of tedflix media
sudo chown -R 1000:100 /mnt/mediapool/tedflix/

# NOT SURE ABOUT THIS PART YET
# files → -rw-rw-r--
find /mnt/mediapool/tedflix/ -type f -exec chmod 664 {} +
# dirs  → drwxr-xr-x
find /mnt/mediapool/tedflix/ -type d -exec chmod 755 {} +
```

## Sync the configs

### Sync configs from marati -> pinheiro
```bash
docker compose -p tedflix stop
# Fix permissions in temp place
sudo rsync -avP --delete --hard-links /var/lib/fast/config/tedflix/ ./tedflix_config/ && sudo chown -R 1000:100 ./tedflix_config/

# Sync to pinheiro
rsync -avP --delete --hard-links -e "ssh" ./tedflix_config/ ted@pinheiro.s3n.io:/mnt/mediapool/tedflix_config/
```
### Sync configs to docker on pinheiro
```bash
function sync_config() {
    DST_CONFIG="/var/lib/docker/volumes/$2/_data"
    sudo rsync -avP --delete --hard-links "/mnt/mediapool/tedflix_config/$1/" "$DST_CONFIG/"
    sudo chown -R $3:$4 "$DST_CONFIG"
}
docker compose -p tedflix stop

# Prowlarr
sync_config "prowlarr" "tedflix_prowlarr_config" 911 911
# Ombi
sync_config "ombi" "tedflix_ombi_config" 1000 100
# Radarr
sync_config "radarr" "tedflix_radarr_config" 1000 100
# Bazarr
sync_config "bazarr" "tedflix_bazarr_config" 1000 100
# Sonarr
sync_config "sonarr" "tedflix_sonarr_config" 1000 100
# Transmission
rm -rf /mnt/mediapool/tedflix_config/transmission/wireguard
sync_config "transmission" "tedflix_transmission_config" 1000 100
# Mariadb
sync_config "mariadb" "tedflix_mariadb_data" 999 999
# plex
sync_config "plex" "tedflix_plex_config" 1000 100

docker compose -p tedflix start
```