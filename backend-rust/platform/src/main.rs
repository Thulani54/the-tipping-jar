//! Platform microservice — third-party apps that embed tipping via an API key
//! (ports the Django `platform` app). Registration needs a JWT (verified via
//! accounts); a raw API key is returned ONCE and only its SHA-256 hash is kept.

use axum::extract::{Path, State};
use axum::http::{header::AUTHORIZATION, HeaderMap};
use axum::routing::{get, post};
use axum::{Json, Router};
use common::{env, AppError};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sha2::{Digest, Sha256};
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
struct Platform {
    id: Uuid,
    owner_user_id: Uuid,
    name: String,
    slug: String,
    website: String,
    description: String,
    approval_status: String,
    platform_key_prefix: String,
    is_active: bool,
    created_at: chrono::DateTime<chrono::Utc>,
}

const PLATFORM_COLUMNS: &str = "id, owner_user_id, name, slug, website, description, approval_status, platform_key_prefix, is_active, created_at";

fn sha256_hex(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    hasher
        .finalize()
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect()
}

/// Returns (raw_key, key_hash, key_prefix). Store hash + prefix; show raw once.
fn generate_key() -> (String, String, String) {
    let raw = format!("tj_platform_sk_v1_{}", Uuid::new_v4().simple());
    let hash = sha256_hex(&raw);
    let prefix = format!("{}...", &raw[..raw.len().min(30)]);
    (raw, hash, prefix)
}

fn slugify(input: &str) -> String {
    let mut out = String::new();
    let mut dash = false;
    for c in input.trim().chars() {
        if c.is_ascii_alphanumeric() {
            out.push(c.to_ascii_lowercase());
            dash = false;
        } else if !dash && !out.is_empty() {
            out.push('-');
            dash = true;
        }
    }
    while out.ends_with('-') {
        out.pop();
    }
    if out.is_empty() {
        out.push_str("platform");
    }
    out
}

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

#[derive(Deserialize)]
struct CreateReq {
    name: String,
    website: Option<String>,
    description: Option<String>,
    slug: Option<String>,
}

#[derive(Deserialize)]
struct VerifyKeyReq {
    key: String,
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "platform" }))
}

async fn register_platform(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<CreateReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    let token = bearer(&headers)?;
    let owner = verify_caller(&st, &token).await?;

    if req.name.trim().is_empty() {
        return Err(AppError::BadRequest("name is required".into()));
    }
    let slug = req
        .slug
        .filter(|s| !s.trim().is_empty())
        .map(|s| slugify(&s))
        .unwrap_or_else(|| slugify(&req.name));
    let (raw_key, key_hash, key_prefix) = generate_key();

    let row: Platform = sqlx::query_as(&format!(
        "INSERT INTO platforms
            (id, owner_user_id, name, slug, website, description, platform_key_hash, platform_key_prefix)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING {PLATFORM_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(owner)
    .bind(req.name.trim())
    .bind(&slug)
    .bind(req.website.unwrap_or_default())
    .bind(req.description.unwrap_or_default())
    .bind(&key_hash)
    .bind(&key_prefix)
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("that slug is already taken".into())
        }
        _ => e.into(),
    })?;

    // The raw key is shown exactly once.
    Ok(Json(json!({
        "platform": row,
        "api_key": raw_key,
        "note": "store this key now — it will not be shown again",
    })))
}

async fn list_platforms(State(st): State<AppState>) -> Result<Json<Vec<Platform>>, AppError> {
    let rows: Vec<Platform> = sqlx::query_as(&format!(
        "SELECT {PLATFORM_COLUMNS} FROM platforms ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn get_platform(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<Platform>, AppError> {
    let row: Platform =
        sqlx::query_as(&format!("SELECT {PLATFORM_COLUMNS} FROM platforms WHERE slug = $1"))
            .bind(slug)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("platform not found".into()))?;
    Ok(Json(row))
}

/// Verify a raw platform API key by hashing it and matching the stored hash.
async fn verify_key(
    State(st): State<AppState>,
    Json(req): Json<VerifyKeyReq>,
) -> Result<Json<Platform>, AppError> {
    let hash = sha256_hex(&req.key);
    let row: Platform = sqlx::query_as(&format!(
        "SELECT {PLATFORM_COLUMNS} FROM platforms WHERE platform_key_hash = $1 AND is_active = TRUE"
    ))
    .bind(hash)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::Unauthorized("invalid platform key".into()))?;
    Ok(Json(row))
}

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS platforms (
            id                  UUID PRIMARY KEY,
            owner_user_id       UUID NOT NULL,
            name                TEXT NOT NULL,
            slug                TEXT UNIQUE NOT NULL,
            website             TEXT NOT NULL DEFAULT '',
            description         TEXT NOT NULL DEFAULT '',
            approval_status     TEXT NOT NULL DEFAULT 'pending',
            platform_key_hash   TEXT UNIQUE,
            platform_key_prefix TEXT NOT NULL DEFAULT '',
            is_active           BOOLEAN NOT NULL DEFAULT TRUE,
            created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
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
        "postgres://postgres:postgres@localhost:5432/platform_db",
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
        .route("/platforms", post(register_platform).get(list_platforms))
        .route("/platforms/verify-key", post(verify_key))
        .route("/platforms/:slug", get(get_platform))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8090");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("platform service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
