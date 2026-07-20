//! Payments microservice — fee maths and the transaction ledger.
//!
//! Mirrors the Django `payments.paystack.calculate_fees` split:
//!   platform_fee = amount * PLATFORM_FEE_PERCENT%   (Tipping Jar's cut)
//!   service_fee  = amount * SERVICE_FEE_PERCENT%    (processor fee, creator-borne)
//!   creator_net  = amount - platform_fee - service_fee
//!
//! `/payments/charge` simulates a successful Paystack capture and records the
//! transaction so a creator's balance can be summed later.

use axum::extract::{Path, State};
use axum::routing::{get, post};
use axum::{Json, Router};
use common::{env, AppError};
use rust_decimal::prelude::FromPrimitive;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Clone)]
struct AppState {
    pool: PgPool,
    platform_pct: Decimal,
    service_pct: Decimal,
}

#[derive(sqlx::FromRow, Serialize)]
struct Transaction {
    id: Uuid,
    reference: String,
    creator_id: Uuid,
    amount: Decimal,
    platform_fee: Decimal,
    service_fee: Decimal,
    creator_net: Decimal,
    status: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

const TXN_COLUMNS: &str =
    "id, reference, creator_id, amount, platform_fee, service_fee, creator_net, status, created_at";

struct Fees {
    platform_fee: Decimal,
    service_fee: Decimal,
    creator_net: Decimal,
}

fn calc_fees(amount: Decimal, platform_pct: Decimal, service_pct: Decimal) -> Fees {
    let hundred = Decimal::from(100);
    let platform_fee = (amount * platform_pct / hundred).round_dp(2);
    let service_fee = (amount * service_pct / hundred).round_dp(2);
    let creator_net = (amount - platform_fee - service_fee).round_dp(2);
    Fees {
        platform_fee,
        service_fee,
        creator_net,
    }
}

fn parse_amount(amount: f64) -> Result<Decimal, AppError> {
    if amount <= 0.0 {
        return Err(AppError::BadRequest("amount must be positive".into()));
    }
    Decimal::from_f64(amount)
        .map(|d| d.round_dp(2))
        .ok_or_else(|| AppError::BadRequest("invalid amount".into()))
}

// ── Request bodies ──────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct QuoteReq {
    amount: f64,
}

#[derive(Deserialize)]
struct ChargeReq {
    creator_id: Uuid,
    amount: f64,
    /// Optional idempotency reference; generated if omitted.
    reference: Option<String>,
}

// ── Handlers ────────────────────────────────────────────────────────────────

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "payments" }))
}

async fn quote(
    State(st): State<AppState>,
    Json(req): Json<QuoteReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    let amount = parse_amount(req.amount)?;
    let f = calc_fees(amount, st.platform_pct, st.service_pct);
    Ok(Json(json!({
        "amount": amount.to_string(),
        "platform_fee": f.platform_fee.to_string(),
        "service_fee": f.service_fee.to_string(),
        "creator_net": f.creator_net.to_string(),
        "total_fee": (f.platform_fee + f.service_fee).to_string(),
        "platform_pct": st.platform_pct.to_string(),
        "service_pct": st.service_pct.to_string(),
    })))
}

async fn charge(
    State(st): State<AppState>,
    Json(req): Json<ChargeReq>,
) -> Result<Json<Transaction>, AppError> {
    let amount = parse_amount(req.amount)?;
    let f = calc_fees(amount, st.platform_pct, st.service_pct);
    let reference = req
        .reference
        .filter(|r| !r.trim().is_empty())
        .unwrap_or_else(|| format!("tj_{}", Uuid::new_v4().simple()));

    // Simulated processor capture: always succeeds in this environment.
    let row: Transaction = sqlx::query_as(&format!(
        "INSERT INTO transactions
            (id, reference, creator_id, amount, platform_fee, service_fee, creator_net, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'completed')
         RETURNING {TXN_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(&reference)
    .bind(req.creator_id)
    .bind(amount)
    .bind(f.platform_fee)
    .bind(f.service_fee)
    .bind(f.creator_net)
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("a transaction with that reference already exists".into())
        }
        _ => e.into(),
    })?;

    Ok(Json(row))
}

async fn get_transaction(
    State(st): State<AppState>,
    Path(reference): Path<String>,
) -> Result<Json<Transaction>, AppError> {
    let row: Transaction =
        sqlx::query_as(&format!("SELECT {TXN_COLUMNS} FROM transactions WHERE reference = $1"))
            .bind(reference)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("transaction not found".into()))?;
    Ok(Json(row))
}

async fn creator_balance(
    State(st): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    let row: (Option<Decimal>, i64) = sqlx::query_as(
        "SELECT COALESCE(SUM(creator_net), 0), COUNT(*)
         FROM transactions WHERE creator_id = $1 AND status = 'completed'",
    )
    .bind(creator_id)
    .fetch_one(&st.pool)
    .await?;
    let net = row.0.unwrap_or_else(|| Decimal::from(0));
    Ok(Json(json!({
        "creator_id": creator_id,
        "net_balance": net.to_string(),
        "transaction_count": row.1,
    })))
}

// ── Bootstrap ───────────────────────────────────────────────────────────────

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS transactions (
            id           UUID PRIMARY KEY,
            reference    TEXT UNIQUE NOT NULL,
            creator_id   UUID NOT NULL,
            amount       NUMERIC(12,2) NOT NULL,
            platform_fee NUMERIC(12,2) NOT NULL DEFAULT 0,
            service_fee  NUMERIC(12,2) NOT NULL DEFAULT 0,
            creator_net  NUMERIC(12,2) NOT NULL DEFAULT 0,
            status       TEXT NOT NULL DEFAULT 'completed',
            created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_txn_creator ON transactions (creator_id)")
        .execute(pool)
        .await?;
    Ok(())
}

async fn connect_with_retry(db_url: &str) -> PgPool {
    for attempt in 1..=30 {
        match PgPoolOptions::new().max_connections(5).connect(db_url).await {
            Ok(pool) => return pool,
            Err(e) => {
                tracing::warn!("db connect attempt {attempt}/30 failed: {e}");
                tokio::time::sleep(std::time::Duration::from_secs(2)).await;
            }
        }
    }
    panic!("could not connect to database after 30 attempts");
}

fn pct_env(key: &str, default: f64) -> Decimal {
    let raw = env(key, &default.to_string());
    raw.parse::<f64>()
        .ok()
        .and_then(Decimal::from_f64)
        .unwrap_or_else(|| Decimal::from_f64(default).unwrap())
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let db_url = env(
        "DATABASE_URL",
        "postgres://postgres:postgres@localhost:5432/payments_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let state = AppState {
        pool,
        platform_pct: pct_env("PLATFORM_FEE_PERCENT", 3.0),
        service_pct: pct_env("SERVICE_FEE_PERCENT", 3.0),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/payments/quote", post(quote))
        .route("/payments/charge", post(charge))
        .route("/payments/:reference", get(get_transaction))
        .route("/payments/creator/:creator_id/balance", get(creator_balance))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8083");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("payments service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
