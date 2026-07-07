#!/bin/sh
set -e

normalize_api_url() {
  url="$1"
  while [ "${url%/}" != "$url" ]; do url="${url%/}"; done
  case "$url" in
    */api) ;;
    *) url="${url}/api" ;;
  esac
  printf '%s' "$url"
}

ONLINE_URL="${ONLINE_API_BASE_URL:-${API_BASE_URL:-https://pos-bar-api-production.up.railway.app/api}}"
OFFLINE_URL="${API_BASE_URL:-$ONLINE_URL}"
ONLINE_URL="$(normalize_api_url "$ONLINE_URL")"
OFFLINE_URL="$(normalize_api_url "$OFFLINE_URL")"

printf '%s\n' \
  "{\"online_api_base_url\":\"${ONLINE_URL}\",\"api_base_url\":\"${OFFLINE_URL}\"}" \
  > /usr/share/nginx/html/app-config.json
sed -i "s|__POS_ONLINE_API_BASE_URL__|${ONLINE_URL}|g" /usr/share/nginx/html/index.html
sed -i "s|__POS_API_BASE_URL__|${OFFLINE_URL}|g" /usr/share/nginx/html/index.html
BUILD_ID="${RAILWAY_GIT_COMMIT_SHA:-${SOURCE_VERSION:-$(date +%s)}}"
sed -i "s|__SW_VERSION__|${BUILD_ID}|g" /usr/share/nginx/html/index.html
printf '%s\n' "{\"version\":\"${BUILD_ID}\"}" > /usr/share/nginx/html/version.json

SW_PATH="/usr/share/nginx/html/flutter_service_worker.js"
if [ -f "$SW_PATH" ]; then
  if ! grep -q "POS_SW_INJECTED" "$SW_PATH"; then
    TMP_SW="${SW_PATH}.tmp"
    cat > "$TMP_SW" <<'EOF'
// POS_SW_INJECTED
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (event) { event.waitUntil(self.clients.claim()); });
self.addEventListener('message', function (event) {
  if (event && event.data === 'skipWaiting') self.skipWaiting();
});

EOF
    cat "$SW_PATH" >> "$TMP_SW"
    mv "$TMP_SW" "$SW_PATH"
  fi
fi
echo "POS Bar Terminal: ONLINE_API_BASE_URL=${ONLINE_URL} API_BASE_URL=${OFFLINE_URL} build=${BUILD_ID}"

PORT="${PORT:-8080}"
sed "s/LISTEN_PORT/${PORT}/g" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
exec nginx -g 'daemon off;'
