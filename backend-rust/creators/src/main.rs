//! Creators microservice — owns creator profiles.
//!
//! Creating a profile requires a valid JWT, which this service validates by
//! calling the accounts service (`ACCOUNTS_URL/internal/verify-token`). It also
//! exposes internal lookups that the tips service uses to resolve a creator.

use axum::extract::{Path, State};
use axum::http::{header::AUTHORIZATION, HeaderMap};
use axum::routing::{get, post};
use axum::{Json, Router};
use common::{env, AppError};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
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
struct Creator {
    id: Uuid,
    user_id: Uuid,
    display_name: String,
    slug: String,
    tagline: String,
    category: String,
    tip_goal: Option<Decimal>,
    is_active: bool,
    kyc_status: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

const CREATOR_COLUMNS: &str =
    "id, user_id, display_name, slug, tagline, category, tip_goal, is_active, kyc_status, created_at";

// ── Helpers ─────────────────────────────────────────────────────────────────

fn slugify(input: &str) -> String {
    let mut out = String::new();
    let mut last_dash = false;
    for c in input.trim().chars() {
        if c.is_ascii_alphanumeric() {
            out.push(c.to_ascii_lowercase());
            last_dash = false;
        } else if !last_dash && !out.is_empty() {
            out.push('-');
            last_dash = true;
        }
    }
    while out.ends_with('-') {
        out.pop();
    }
    if out.is_empty() {
        out.push_str("creator");
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

#[derive(Deserialize)]
struct VerifyResp {
    user_id: String,
    #[allow(dead_code)]
    email: String,
    #[allow(dead_code)]
    role: String,
}

/// Ask the accounts service to validate the caller's token. This is the
/// creators -> accounts service-to-service hop.
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
    let body: VerifyResp = resp.json().await?;
    Uuid::parse_str(&body.user_id)
        .map_err(|_| AppError::Internal("accounts returned a bad user id".into()))
}

// ── Request bodies ──────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct CreateReq {
    display_name: String,
    tagline: Option<String>,
    category: Option<String>,
    tip_goal: Option<f64>,
    slug: Option<String>,
}

// ── Handlers ────────────────────────────────────────────────────────────────

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "creators" }))
}

async fn create_creator(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<CreateReq>,
) -> Result<Json<Creator>, AppError> {
    let token = bearer(&headers)?;
    let user_id = verify_caller(&st, &token).await?;

    let display = req.display_name.trim();
    if display.is_empty() {
        return Err(AppError::BadRequest("display_name is required".into()));
    }
    let slug = req
        .slug
        .filter(|s| !s.trim().is_empty())
        .map(|s| slugify(&s))
        .unwrap_or_else(|| slugify(display));
    let tip_goal = req
        .tip_goal
        .and_then(Decimal::from_f64_retain)
        .map(|d| d.round_dp(2));

    let row: Creator = sqlx::query_as(&format!(
        "INSERT INTO creator_profiles (id, user_id, display_name, slug, tagline, category, tip_goal)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING {CREATOR_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(user_id)
    .bind(display)
    .bind(&slug)
    .bind(req.tagline.unwrap_or_default())
    .bind(req.category.unwrap_or_default())
    .bind(tip_goal)
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("that slug or user already has a profile".into())
        }
        _ => e.into(),
    })?;

    Ok(Json(row))
}

async fn list_creators(State(st): State<AppState>) -> Result<Json<Vec<Creator>>, AppError> {
    let rows: Vec<Creator> = sqlx::query_as(&format!(
        "SELECT {CREATOR_COLUMNS} FROM creator_profiles WHERE is_active = TRUE ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn get_by_slug(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<Creator>, AppError> {
    let row: Creator =
        sqlx::query_as(&format!("SELECT {CREATOR_COLUMNS} FROM creator_profiles WHERE slug = $1"))
            .bind(slug)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("creator not found".into()))?;
    Ok(Json(row))
}

/// Internal: resolve a creator by id (used by the tips service).
async fn get_by_id(
    State(st): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Creator>, AppError> {
    let row: Creator =
        sqlx::query_as(&format!("SELECT {CREATOR_COLUMNS} FROM creator_profiles WHERE id = $1"))
            .bind(id)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("creator not found".into()))?;
    Ok(Json(row))
}

// ── Bootstrap ───────────────────────────────────────────────────────────────

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS creator_profiles (
            id           UUID PRIMARY KEY,
            user_id      UUID UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            slug         TEXT UNIQUE NOT NULL,
            tagline      TEXT NOT NULL DEFAULT '',
            category     TEXT NOT NULL DEFAULT '',
            tip_goal     NUMERIC(10,2),
            is_active    BOOLEAN NOT NULL DEFAULT TRUE,
            kyc_status   TEXT NOT NULL DEFAULT 'not_started',
            created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
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
        "postgres://postgres:postgres@localhost:5432/creators_db",
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
        .route("/creators", post(create_creator).get(list_creators))
        .route("/creators/:slug", get(get_by_slug))
        .route("/internal/creators/:id", get(get_by_id))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8082");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("creators service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
