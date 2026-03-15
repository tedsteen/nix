## First time setup
### Home Assistant
* Allow access through reverse proxy by adding this to `configuration.yaml`
    ```yaml
    http:
    use_x_forwarded_for: true
    trusted_proxies:
        - 172.18.0.0/16 # Docker bridge network range
    ```
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
