FROM node:24.5.0-alpine

WORKDIR /app
COPY package.json server.js ./
COPY public ./public
RUN mkdir /data && chown node:node /data

ENV NODE_ENV=production
EXPOSE 3000

USER node
CMD ["node", "server.js"]
