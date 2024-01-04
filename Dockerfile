# build stage
FROM node:lts-alpine as build-stage
WORKDIR /
COPY package*.json ./
COPY .snyk ./
RUN mkdir -p public
RUN npm install
COPY . .
RUN npm run build
RUN node tools/generate-health.js

# production stage
FROM openresty/openresty:bookworm as production-stage
COPY --from=build-stage /dist /usr/share/nginx/html
COPY ./docker/nginx.conf /etc/nginx/conf.d/default.conf.template

# Default configuration
ENV PORT 80
ENV HEALTH_HTTP_PORT 8080
ENV SERVER_NAME _

# Required to use envsubst
RUN apt-get update && apt-get install -y gettext-base

CMD ["sh", "-c", "envsubst '${PORT},${HEALTH_HTTP_PORT},${SERVER_NAME}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && /usr/bin/openresty -g 'daemon off;'"]
