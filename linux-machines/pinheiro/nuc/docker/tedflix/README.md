# Tedflix
Note: This is only a proof of concept to showcase how to setup an automated media server using docker compose. This is not actually running anywhere.

## First time setup
### Sonarr
Add transmission download client using host `transmission` and port `9091`
### Radarr
Add transmission download client using host `transmission` and port `9091`
### Prowlarr
* Add indexers
* Add `flaresolverr` as indexer proxy with tag `flaresolver`
* Add apps `Sonarr` and `Radarr`
### Bazarr
* Go through the [guides](https://trash-guides.info/Bazarr/)
  * Sonar address is `sonarr`, Radarr address is `radarr`.
  * Best subtitles providers can be found [here](https://wiki.bazarr.media/bazarr-stats/)
  * I use Anti-Captcha (login to find key)
### Ombi
* Add plex config using host `plex`, port `32400` and token from [here](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/)
  * If plex is forcing secure connections make sure Ombi is using SSL and if there is no valid certificate in Ombi, make sure to ignore certificate errors (needs restart)
* Add sonarr config using host `sonarr`, port `8989` and api key from [here](http://sonarr.tedflix.s3n.io/settings/general)
* Add radarr config using host `radarr`, port `7878` and api key from [here](http://radarr.tedflix.s3n.io/settings/general)
