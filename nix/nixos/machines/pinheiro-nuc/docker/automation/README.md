## First time setup
### Home Assistant
* Home Assistant is exposed directly on the host at `http://pinheiro-nuc/home-assistant` (redirects to `:18123`)
* Add `influx_db_token: <token-created-when-setting-up-influxdb>` to `secrets.yaml`
* Connect HA to influxdb by adding this to `configuration.yaml`
    ```yaml
    influxdb:
        api_version: 2
        ssl: false
        host: influxdb
        port: 8086
        token: !secret influx_db_token
        organization: pinheiro
        bucket: everything
        tags:
            source: HA
        tags_attributes:
            - friendly_name
        default_measurement: units
    ```
### Node Red
* Install these palettes
    * https://flows.nodered.org/node/node-red-contrib-home-assistant-websocket
        * Follow [this guide](https://zachowj.github.io/node-red-contrib-home-assistant-websocket/guide/#configuration) to connect Node Red with HASS
            * Home assistant base URL: `http://home-assistant:8123`
