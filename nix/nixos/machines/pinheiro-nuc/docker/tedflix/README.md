# Tedflix
Note: This is only a proof of concept to showcase how to setup an automated media server using docker compose. This is not actually running anywhere.

## First time setup
Connect it all...

### Prowlarr
* Add indexers
* Add `flaresolverr` as indexer proxy with tag `flaresolver`
* Add apps `Sonarr` and `Radarr` (Sonarr and Radarr addresses are `http://sonarr:8989` and `http://radarr:7878` respectively)
### Sonarr
* Add transmission download client using host `transmission` and port `9091`
  * Set category / TV category to `sonarr`
* Add Indexers via prowlarr (URL is http://prowlarr:9696/<your-indexer>)
### Radarr
* Add transmission download client using host `transmission` and port `9091`
  * Set category / movie category to `radarr`
* Add Indexers via prowlarr (URL is http://prowlarr:9696/<your-indexer>)

### Transmission categories
Transmission does not expose categories the same way clients like qBittorrent do. When Sonarr or Radarr is configured with a category, new downloads are placed in a category subdirectory under Transmission's download directory, for example:

* `/media/downloads/complete/<yymm>/sonarr/...`
* `/media/downloads/complete/<yymm>/radarr/...`

Keep the categories configured in Sonarr and Radarr so they only track their own downloads instead of the entire shared Transmission queue. This also keeps Unpackerr from repeatedly inspecting unrelated or manually added completed torrents.
### Bazarr
* Go through the [guides](https://trash-guides.info/Bazarr/)
  * Sonar address is `sonarr`, Radarr address is `radarr`.
  * Best subtitles providers can be found [here](https://wiki.bazarr.media/bazarr-stats/)
  * I use Anti-Captcha (login to find key)
### Ombi
* Add plex config using host `plex`, port `32400` and token from [here](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/)
  * If plex is forcing secure connections make sure Ombi is using SSL and if there is no valid certificate in Ombi, make sure to ignore certificate errors (needs restart)
* Add sonarr config using host `sonarr`, port `8989` and api key from [here](http://pinheiro-nuc/sonarr/settings/general)
* Add radarr config using host `radarr`, port `7878` and api key from [here](http://pinheiro-nuc/radarr/settings/general)
