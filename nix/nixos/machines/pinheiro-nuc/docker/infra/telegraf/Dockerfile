FROM telegraf:alpine
COPY telegraf.conf /etc/telegraf/telegraf.conf
# NOTE: To be able to access the docker.sock we need to do this (see: https://github.com/influxdata/telegraf/issues/10031#issuecomment-1026012770)
USER root

ENTRYPOINT /bin/sh -c "telegraf"