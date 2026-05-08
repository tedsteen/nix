FROM nodered/node-red:latest

USER root
COPY package.json /usr/src/pinheiro-node-red/package.json
COPY entrypoint.sh /usr/src/pinheiro-node-red/entrypoint.sh
RUN chown -R node-red:root /usr/src/pinheiro-node-red \
  && chmod +x /usr/src/pinheiro-node-red/entrypoint.sh
USER node-red

ENTRYPOINT ["/usr/src/pinheiro-node-red/entrypoint.sh"]
