//! Enterprise microservice — agency/enterprise accounts (ports the Django
//! `enterprise` app, core `Enterprise` entity). Creating one requires a valid
//! JWT, verified via the accounts service.

use axum::extract::{Path, State};
use axum::http::{header::AUTHORIZATION, HeaderMap};
use axum::routing::{get, post};
use axum::{Json, Router};
use common::{env, AppError};
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
struct Enterprise {
    id: Uuid,
    admin_user_id: Uuid,
    name: String,
    slug: String,
    plan: String,
    website: String,
    approval_status: String,
    contact_name: String,
    contact_email: String,
    contact_phone: String,
    is_active: bool,
    created_at: chrono::DateTime<chrono::Utc>,
}

const ENT_COLUMNS: &str = "id, admin_user_id, name, slug, plan, website, approval_status, contact_name, contact_email, contact_phone, is_active, created_at";

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
        out.push_str("enterprise");
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
    let body: VerifyResp = resp.json().await?;
    Uuid::parse_str(&body.user_id)
        .map_err(|_| AppError::Internal("accounts returned a bad user id".into()))
}

#[derive(Deserialize)]
struct CreateReq {
    name: String,
    plan: Option<String>,
    website: Option<String>,
    contact_name: Option<String>,
    contact_email: Option<String>,
    contact_phone: Option<String>,
    slug: Option<String>,
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "enterprise" }))
}

async fn create_enterprise(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<CreateReq>,
) -> Result<Json<Enterprise>, AppError> {
    let token = bearer(&headers)?;
    let admin_id = verify_caller(&st, &token).await?;

    if req.name.trim().is_empty() {
        return Err(AppError::BadRequest("name is required".into()));
    }
    let slug = req
        .slug
        .filter(|s| !s.trim().is_empty())
        .map(|s| slugify(&s))
        .unwrap_or_else(|| slugify(&req.name));

    let row: Enterprise = sqlx::query_as(&format!(
        "INSERT INTO enterprises
            (id, admin_user_id, name, slug, plan, website, contact_name, contact_email, contact_phone)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING {ENT_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(admin_id)
    .bind(req.name.trim())
    .bind(&slug)
    .bind(req.plan.unwrap_or_else(|| "growth".into()))
    .bind(req.website.unwrap_or_default())
    .bind(req.contact_name.unwrap_or_default())
    .bind(req.contact_email.unwrap_or_default())
    .bind(req.contact_phone.unwrap_or_default())
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("that slug or admin already has an enterprise".into())
        }
        _ => e.into(),
    })?;
    Ok(Json(row))
}

async fn list_enterprises(State(st): State<AppState>) -> Result<Json<Vec<Enterprise>>, AppError> {
    let rows: Vec<Enterprise> = sqlx::query_as(&format!(
        "SELECT {ENT_COLUMNS} FROM enterprises WHERE is_active = TRUE ORDER BY name LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn get_enterprise(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<Enterprise>, AppError> {
    let row: Enterprise =
        sqlx::query_as(&format!("SELECT {ENT_COLUMNS} FROM enterprises WHERE slug = $1"))
            .bind(slug)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("enterprise not found".into()))?;
    Ok(Json(row))
}

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS enterprises (
            id              UUID PRIMARY KEY,
            admin_user_id   UUID UNIQUE NOT NULL,
            name            TEXT NOT NULL,
            slug            TEXT UNIQUE NOT NULL,
            plan            TEXT NOT NULL DEFAULT 'growth',
            website         TEXT NOT NULL DEFAULT '',
            approval_status TEXT NOT NULL DEFAULT 'pending',
            contact_name    TEXT NOT NULL DEFAULT '',
            contact_email   TEXT NOT NULL DEFAULT '',
            contact_phone   TEXT NOT NULL DEFAULT '',
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
        "postgres://postgres:postgres@localhost:5432/enterprise_db",
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
        .route("/enterprises", post(create_enterprise).get(list_enterprises))
        .route("/enterprises/:slug", get(get_enterprise))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8087");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("enterprise service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
