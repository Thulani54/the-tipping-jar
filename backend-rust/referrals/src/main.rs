//! Referrals microservice — one referral code per user + a lookup for signups
//! (ports the Django `referrals` app). Code creation needs a valid JWT,
//! verified via the accounts service.

use axum::extract::{Path, State};
use axum::http::{header::AUTHORIZATION, HeaderMap};
use axum::routing::{get, post};
use axum::{Json, Router};
use common::{env, AppError};
use rust_decimal::Decimal;
use serde::Serialize;
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Clone)]
struct AppState {
    pool: PgPool,
    http: reqwest::Client,
    accounts_url: String,
}

#[derive(sqlx::FromRow, Serialize)]
struct ReferralCode {
    id: Uuid,
    owner_user_id: Uuid,
    code: String,
    commission_rate: Decimal,
    is_active: bool,
    created_at: chrono::DateTime<chrono::Utc>,
}

const CODE_COLUMNS: &str =
    "id, owner_user_id, code, commission_rate, is_active, created_at";

fn bearer(headers: &HeaderMap) -> Result<String, AppError> {
    let raw = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or_else(|| AppError::Unauthorized("missing Authorization header".into()))?;
    raw.strip_prefix("Bearer ")
        .map(|t| t.to_string())
        .ok_or_else(|| AppError::Unauthorized("expected 'Bearer <token>'".into()))
}

async fn verify_caller(st: &AppState, token: &str) -> Result<Uuid, AppError> {
    let resp = st
        .http
        .post(format!("{}/internal/verify-token", st.accounts_url))
        .json(&json!({ "token": token }))
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Unauthorized("token rejected by accounts".into()));
    }
    let body: serde_json::Value = resp.json().await?;
    let uid = body
        .get("user_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| AppError::Internal("accounts returned no user id".into()))?;
    Uuid::parse_str(uid).map_err(|_| AppError::Internal("accounts returned a bad user id".into()))
}

/// Deterministic-ish 8-char uppercase code derived from a v4 UUID.
fn gen_code() -> String {
    Uuid::new_v4().simple().to_string()[..8].to_uppercase()
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "referrals" }))
}

/// Get-or-create the caller's referral code (one per user).
async fn my_code(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ReferralCode>, AppError> {
    let token = bearer(&headers)?;
    let owner = verify_caller(&st, &token).await?;

    if let Some(existing) = sqlx::query_as::<_, ReferralCode>(&format!(
        "SELECT {CODE_COLUMNS} FROM referral_codes WHERE owner_user_id = $1"
    ))
    .bind(owner)
    .fetch_optional(&st.pool)
    .await?
    {
        return Ok(Json(existing));
    }

    // 1% default commission, mirroring the Django default of 0.0100.
    let row: ReferralCode = sqlx::query_as(&format!(
        "INSERT INTO referral_codes (id, owner_user_id, code, commission_rate)
         VALUES ($1,$2,$3,$4) RETURNING {CODE_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(owner)
    .bind(gen_code())
    .bind(Decimal::new(100, 4)) // 0.0100
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn lookup_code(
    State(st): State<AppState>,
    Path(code): Path<String>,
) -> Result<Json<ReferralCode>, AppError> {
    let row: ReferralCode = sqlx::query_as(&format!(
        "SELECT {CODE_COLUMNS} FROM referral_codes WHERE code = $1 AND is_active = TRUE"
    ))
    .bind(code.to_uppercase())
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("referral code not found".into()))?;
    Ok(Json(row))
}

async fn list_codes(State(st): State<AppState>) -> Result<Json<Vec<ReferralCode>>, AppError> {
    let rows: Vec<ReferralCode> = sqlx::query_as(&format!(
        "SELECT {CODE_COLUMNS} FROM referral_codes ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS referral_codes (
            id              UUID PRIMARY KEY,
            owner_user_id   UUID UNIQUE NOT NULL,
            code            TEXT UNIQUE NOT NULL,
            commission_rate NUMERIC(5,4) NOT NULL DEFAULT 0.0100,
            is_active       BOOLEAN NOT NULL DEFAULT TRUE,
            created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
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

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let db_url = env(
        "DATABASE_URL",
        "postgres://postgres:postgres@localhost:5432/referrals_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let state = AppState {
        pool,
        http: reqwest::Client::new(),
        accounts_url: env("ACCOUNTS_URL", "http://localhost:8081"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/codes", post(my_code).get(list_codes))
        .route("/codes/:code", get(lookup_code))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8089");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("referrals service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
