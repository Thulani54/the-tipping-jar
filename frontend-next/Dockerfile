# ── deps ─────────────────────────────────────────────────────────────────────
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

# ── builder ──────────────────────────────────────────────────────────────────
FROM node:22-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# NEXT_PUBLIC_* vars are inlined at build time — pass the API base in here.
ARG NEXT_PUBLIC_API_BASE=https://api.tippingjar.co.za/api/v2
ENV NEXT_PUBLIC_API_BASE=$NEXT_PUBLIC_API_BASE
# Set to 1 ONLY for the temporary plain-HTTP IP preview (relaxes HSTS + CSP
# upgrade-insecure-requests). Unset/0 for real HTTPS builds.
ARG PREVIEW_HTTP=0
ENV PREVIEW_HTTP=$PREVIEW_HTTP
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ── runner ───────────────────────────────────────────────────────────────────
FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
RUN groupadd -r next && useradd -r -g next next
COPY --from=builder /app/public ./public
COPY --from=builder --chown=next:next /app/.next/standalone ./
COPY --from=builder --chown=next:next /app/.next/static ./.next/static
USER next
EXPOSE 3000
CMD ["node", "server.js"]
