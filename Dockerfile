# POS Bar Floor Terminal — Flutter web PWA for Railway
FROM ghcr.io/cirruslabs/flutter:3.19.6 AS build

WORKDIR /app

ARG API_BASE_URL=https://pos.rosebanktavern.co.tz/api

COPY pubspec.yaml pubspec.lock ./
COPY packages/pos_bar_core packages/pos_bar_core
RUN flutter pub get

COPY . .
RUN flutter config --enable-web \
    && flutter build web --release --base-href / --dart-define=API_URL="${API_BASE_URL}"

FROM nginx:1.27-alpine AS runtime

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf.template
COPY deploy/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY --from=build /app/build/web /usr/share/nginx/html

ENV API_BASE_URL=https://pos.rosebanktavern.co.tz/api
ENV ONLINE_API_BASE_URL=https://pos.rosebanktavern.co.tz/api
ENV PORT=8080
EXPOSE 8080

CMD ["/docker-entrypoint.sh"]
