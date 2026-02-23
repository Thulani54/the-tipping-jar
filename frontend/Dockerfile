# ── Stage 1: Build Flutter Web ─────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy pubspec files first for layer caching
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy the rest of the source
COPY . .

# Build for web (production)
ARG API_BASE_URL=https://api.tippingjar.co.za
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ── Disable Flutter's service worker entirely ───────────────────────────────────
# Flutter's SW caches main.dart.js for up to 1 year; without a content-hash in
# the filename the browser never fetches the new build. Disabling the SW means
# every request goes to nginx, whose cache headers control freshness correctly.
#
# 1. Set serviceWorkerVersion: null in flutter_bootstrap.js  →  Flutter won't
#    register a SW at all.
# 2. Replace flutter_service_worker.js with a self-unregistering one-liner so
#    any EXISTING SW that's already installed on user devices unregisters itself
#    the moment the browser checks for an update.
RUN sed -i \
      -e 's/serviceWorkerVersion: "[^"]*"/serviceWorkerVersion: null/g' \
      -e "s/serviceWorkerVersion: '[^']*'/serviceWorkerVersion: null/g" \
      /app/build/web/flutter_bootstrap.js

RUN printf '%s\n' \
  "// Self-unregistering stub — removes itself and any leftover caches." \
  "self.addEventListener('install', function(e) { e.waitUntil(self.skipWaiting()); });" \
  "self.addEventListener('activate', function(e) {" \
  "  e.waitUntil(" \
  "    caches.keys()" \
  "      .then(function(n){return Promise.all(n.map(function(c){return caches.delete(c)}))})" \
  "      .then(function(){return self.registration.unregister()})" \
  "      .then(function(){return self.clients.matchAll({type:'window'})})" \
  "      .then(function(cl){cl.forEach(function(c){c.navigate(c.url).catch(function(){})})})" \
  "  );" \
  "});" \
  > /app/build/web/flutter_service_worker.js

# ── Stage 2: Serve with nginx ──────────────────────────────────────────────────
FROM nginx:alpine

# Copy the built Flutter web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Stamp a unique build version into the flutter_bootstrap.js reference so that
# the browser always fetches a fresh copy of the bootstrap on every deploy.
RUN BUILD_TS=$(date +%s) && \
    sed -i "s|flutter_bootstrap\.js?v=[^\"]*|flutter_bootstrap.js?v=${BUILD_TS}|g" \
        /usr/share/nginx/html/index.html

# nginx: serve Flutter web with correct cache semantics
# ─ index.html, all JS, all JSON → no-cache (Flutter doesn't hash filenames)
# ─ Binary assets (images, fonts) → 1 year (URLs don't change between builds)
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    gzip on;\n\
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/wasm;\n\
\n\
    # All JS and JSON files — never cache.\n\
    # Flutter does NOT content-hash main.dart.js so a 1-year cache means users\n\
    # get stuck on the old build forever. Serve every JS/JSON fresh.\n\
    location ~* \\.(?:js|json|map)$ {\n\
        try_files $uri $uri/ /index.html;\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
        expires 0;\n\
    }\n\
\n\
    # SPA fallback — never cache HTML\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
    }\n\
\n\
    # Binary assets (images, fonts, wasm) — safe to cache for a year\n\
    # because their URLs include a content-hash or never change.\n\
    location ~* \\.(?:png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|wasm)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
\n\
    add_header X-Frame-Options "SAMEORIGIN" always;\n\
    add_header X-Content-Type-Options "nosniff" always;\n\
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
