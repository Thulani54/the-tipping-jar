# ── Stage 1: Build Flutter Web ─────────────────────────────────────────────────
# Use official Flutter Docker image — always gets a current stable Flutter
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

# ── Stage 2: Serve with nginx ──────────────────────────────────────────────────
FROM nginx:alpine

# Copy the built Flutter web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Stamp a unique build version into flutter_bootstrap.js reference so every
# deployment automatically busts the browser cache — no manual version bumps needed.
RUN BUILD_TS=$(date +%s) && \
    sed -i "s|flutter_bootstrap\.js?v=[^\"]*|flutter_bootstrap.js?v=${BUILD_TS}|g" \
        /usr/share/nginx/html/index.html

# nginx config for SPA routing (all 404s → index.html)
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    gzip on;\n\
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;\n\
\n\
    # index.html — never cache (exact match, also covers SPA fallback)\n\
    location = /index.html {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
    }\n\
\n\
    # flutter_bootstrap.js — never cache (served with unique ?v= per build)\n\
    location = /flutter_bootstrap.js {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
    }\n\
\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
    }\n\
\n\
    # Flutter runtime files — filenames never change, so must NOT be cached\n\
    location = /flutter_service_worker.js {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
        expires 0;\n\
    }\n\
    location = /flutter.js {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
        expires 0;\n\
    }\n\
    location = /version.json {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
        expires 0;\n\
    }\n\
    location = /manifest.json {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
        expires 0;\n\
    }\n\
\n\
    # Hashed Flutter assets can be cached forever (filenames change each build)\n\
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {\n\
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
