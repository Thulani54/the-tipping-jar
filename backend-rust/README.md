# Tipping Jar — Rust microservices

A Rust rewrite of the Tipping Jar backend, split into independently deployable
services that cooperate over HTTP. Built with **axum**, **sqlx** (Postgres) and
**tokio**, packaged as a single image run 11 ways via docker-compose.

## Services

| Service        | Port | Owns                         | Talks to                       |
|----------------|------|------------------------------|--------------------------------|
| `accounts`     | 8081 | users + JWT (Argon2id)       | —                              |
| `creators`     | 8082 | creator profiles             | `accounts`                     |
| `payments`     | 8083 | fee split (3%+3%) + ledger   | —                              |
| `tips`         | 8084 | tips                         | `creators` + `payments`        |
| `blog`         | 8085 | blog posts                   | —                              |
| `careers`      | 8086 | job openings                 | —                              |
| `enterprise`   | 8087 | enterprise/agency accounts   | `accounts`                     |
| `support`      | 8088 | contact messages + disputes  | —                              |
| `referrals`    | 8089 | referral codes               | `accounts`                     |
| `platform`     | 8090 | third-party apps + API keys  | `accounts`                     |
| `admin_portal` | 8091 | dashboard (no DB)            | `creators`+`tips`+`support`    |

Each data-owning service has its own database on a shared Postgres instance;
services never touch each other's tables — they call each other's HTTP APIs.
`admin_portal` owns no database and aggregates the others live.

### How a tip flows (inter-service call graph)

```
client ──POST /tips──▶ tips
                        ├─ GET  creators/creators/{slug}   (validate creator)
                        └─ POST payments/payments/charge   (capture + fee split)
                             tips then writes the tip with the fee snapshot
```

The fee split mirrors the original Django `calculate_fees`:
`platform_fee = 3%`, `service_fee = 3%`, `creator_net = amount − fees`.

## Run it

```bash
docker compose up --build -d
./smoke-test.sh            # end-to-end proof the services cooperate
```

## Deployment (VPS 154.66.199.174)

- Published ports bind to **127.0.0.1 only**. The public edge is **nginx on 443**
  (TLS), reverse-proxying `https://<host>/api/v2/<service>/…` to the loopback
  port of each service. Nothing is exposed on the raw ports.
- `db` Postgres is **not** published to the host, so it never clashes with the
  system Postgres already on `:5432`.
- Only `accounts` holds the `JWT_SECRET`; other services verify tokens by
  calling `accounts`, so the secret is never distributed.

Public base URL: `https://api.tippingjar.co.za/api/v2/` (once DNS + cert are
live), e.g. `GET /api/v2/creators/creators`, `POST /api/v2/tips/tips`.

## Endpoints (summary)

- **accounts** — `POST /auth/register|login`, `GET /auth/me`, `POST /internal/verify-token`, `GET /internal/users/{id}`
- **creators** — `POST|GET /creators`, `GET /creators/{slug}`, `GET /internal/creators/{id}`
- **payments** — `POST /payments/quote|charge`, `GET /payments/{ref}`, `GET /payments/creator/{id}/balance`
- **tips** — `POST|GET /tips`, `GET /tips/creator/{id}`
- **blog** — `POST|GET /posts`, `GET /posts/{slug}`
- **careers** — `POST|GET /jobs`, `GET /jobs/{id}`
- **enterprise** — `POST|GET /enterprises`, `GET /enterprises/{slug}`
- **support** — `POST|GET /contact`, `POST|GET /disputes`, `GET /disputes/{token}`
- **referrals** — `POST|GET /codes`, `GET /codes/{code}`
- **platform** — `POST|GET /platforms`, `GET /platforms/{slug}`, `POST /platforms/verify-key`
- **admin_portal** — `GET /dashboard`
