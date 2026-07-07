SmartPool (Tasmota + NeoPool)
Hardware:
* Atom Lite: https://docs.m5stack.com/en/core/ATOM%20Lite
* Tail485: https://docs.m5stack.com/en/atom/tail485
* Bringing it together: https://tasmota.github.io/docs/NeoPool/

Software:
* Firmware: https://github.com/alexdelprete/ha-sugar-valley-neopool/tree/main/firmware (ESP32 Tasmota build with neopool `NeoPool_ESP32_tasmota32.factory.bin`)
* Flash
  * List devices `ls /dev/cu.`
  * Erease       `esptool --chip esp32 --port /dev/cu.usbserial-8552562FF5 --baud 115200 erase-flash`
  * Flash        `esptool --chip esp32 --port /dev/cu.usbserial-8552562FF5 --baud 115200 write-flash -z 0x0 ~/Downloads/NeoPool_ESP32_tasmota32.factory.bin`
* HA Integration: https://github.com/alexdelprete/ha-sugar-valley-neopool

Data flow:
```
NeoPool controller --RS485(Tail485)-- Atom Lite (Tasmota NeoPool)
        | WiFi + MQTT (tele/<topic>/SENSOR)
        v
   mosquitto broker --> HA neopool integration --> sensor.* entities
        |                                               |
        |                          HA /api/prometheus (exports hass_sensor_*)
        v                                               v
                 Alloy scrape (already configured) --> otel-lgtm --> Grafana
```
The mosquitto broker is provisioned in `../docker-compose.yaml`. The HA
Prometheus export and the Alloy scrape of HA are already wired up in nix, so
once the pool entities exist in HA they show up in Grafana as `hass_sensor_*`
automatically. The steps below are the remaining manual (non-code) config.

Manual setup:

1. Tasmota device config (on the Atom Lite web UI, after flashing)
   * Configure WiFi to join the LAN.
   * Set the module/template for Atom Lite + Tail485 so the NeoPool driver
     talks over the RS485 serial pins (see https://tasmota.github.io/docs/NeoPool/).
   * Configure MQTT: host = the NUC's LAN IP, port = 1883, no user/pass
     (broker allows anonymous on the LAN). Note the Tasmota `Topic`.
   * Verify `tele/<topic>/SENSOR` messages are arriving, e.g. from the NUC:
     `mosquitto_sub -h localhost -t 'tele/#' -v`

2. Home Assistant MQTT integration (one-time, via HA UI)
   * Settings -> Devices & Services -> Add Integration -> MQTT.
   * Broker = `mosquitto` (reachable on the compose network), port `1883`,
     no credentials.
   * (HA stores the broker connection in its config volume, so this is not
     captured in git.)

3. NeoPool integration (via HA UI)
   * The `sugar_valley_neopool` component is vendored into the repo at
     `../home-assistant/custom_components/` and bind-mounted read-only, so no
     HACS/manual install is needed. To update it, replace that folder with a
     newer release from https://github.com/alexdelprete/ha-sugar-valley-neopool
     and redeploy.
   * Settings -> Devices & Services -> Add Integration -> Sugar Valley NeoPool,
     entering the device name and the Tasmota `Topic` from step 1.
   * The pool `sensor.*` entities then appear in HA and flow to Grafana.

Grafana:
* No infra change needed — pool metrics arrive as `hass_sensor_*` via the
  existing HA Prometheus scrape.
* Check exact metric names in Grafana -> Explore (pH / redox have
  non-standard units). A dedicated pool dashboard can be added later under
  `../../infra/grafana/dashboards/` and referenced from
  `services.observabilityStack.extraDashboardPaths`.