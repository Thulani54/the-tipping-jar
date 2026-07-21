# ── Builder ──────────────────────────────────────────────────────────────────
# Compiles the whole Cargo workspace once, producing every service binary.
FROM rust:1-bookworm AS builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY common ./common
COPY accounts ./accounts
COPY creators ./creators
COPY payments ./payments
COPY tips ./tips
COPY blog ./blog
COPY careers ./careers
COPY enterprise ./enterprise
COPY support ./support
COPY referrals ./referrals
COPY platform ./platform
COPY admin_portal ./admin_portal
COPY scheduler ./scheduler

RUN cargo build --release --workspace

# ── Runtime ──────────────────────────────────────────────────────────────────
# One slim image carrying every binary; docker-compose picks which one to run
# per service via the `command:` field.
FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/accounts     /usr/local/bin/accounts
COPY --from=builder /app/target/release/creators     /usr/local/bin/creators
COPY --from=builder /app/target/release/payments     /usr/local/bin/payments
COPY --from=builder /app/target/release/tips         /usr/local/bin/tips
COPY --from=builder /app/target/release/blog         /usr/local/bin/blog
COPY --from=builder /app/target/release/careers      /usr/local/bin/careers
COPY --from=builder /app/target/release/enterprise   /usr/local/bin/enterprise
COPY --from=builder /app/target/release/support      /usr/local/bin/support
COPY --from=builder /app/target/release/referrals    /usr/local/bin/referrals
COPY --from=builder /app/target/release/platform     /usr/local/bin/platform
COPY --from=builder /app/target/release/admin_portal /usr/local/bin/admin_portal
COPY --from=builder /app/target/release/scheduler    /usr/local/bin/scheduler

EXPOSE 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090 8091 8092

CMD ["/bin/sh", "-c", "echo 'set command: to a service name' && exit 1"]
