//! Support microservice — contact messages and disputes (ports the Django
//! `support` app). Public submission endpoints; disputes are trackable by token.

use axum::extract::{Path, State};
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
}

#[derive(sqlx::FromRow, Serialize)]
struct ContactMessage {
    id: Uuid,
    name: String,
    email: String,
    subject: String,
    message: String,
    is_resolved: bool,
    created_at: chrono::DateTime<chrono::Utc>,
}

const CONTACT_COLUMNS: &str = "id, name, email, subject, message, is_resolved, created_at";

#[derive(sqlx::FromRow, Serialize)]
struct Dispute {
    id: Uuid,
    name: String,
    email: String,
    reason: String,
    description: String,
    tip_ref: String,
    status: String,
    token: Uuid,
    created_at: chrono::DateTime<chrono::Utc>,
}

const DISPUTE_COLUMNS: &str =
    "id, name, email, reason, description, tip_ref, status, token, created_at";

#[derive(Deserialize)]
struct ContactReq {
    name: String,
    email: String,
    subject: Option<String>,
    message: String,
}

#[derive(Deserialize)]
struct DisputeReq {
    name: String,
    email: String,
    reason: String,
    description: String,
    tip_ref: Option<String>,
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "support" }))
}

async fn create_contact(
    State(st): State<AppState>,
    Json(req): Json<ContactReq>,
) -> Result<Json<ContactMessage>, AppError> {
    if req.name.trim().is_empty() || req.message.trim().is_empty() {
        return Err(AppError::BadRequest("name and message are required".into()));
    }
    let row: ContactMessage = sqlx::query_as(&format!(
        "INSERT INTO contact_messages (id, name, email, subject, message)
         VALUES ($1,$2,$3,$4,$5) RETURNING {CONTACT_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(req.name.trim())
    .bind(req.email.trim().to_lowercase())
    .bind(req.subject.unwrap_or_else(|| "general".into()))
    .bind(req.message)
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn list_contacts(State(st): State<AppState>) -> Result<Json<Vec<ContactMessage>>, AppError> {
    let rows: Vec<ContactMessage> = sqlx::query_as(&format!(
        "SELECT {CONTACT_COLUMNS} FROM contact_messages ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn create_dispute(
    State(st): State<AppState>,
    Json(req): Json<DisputeReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    if req.name.trim().is_empty() || req.description.trim().is_empty() {
        return Err(AppError::BadRequest(
            "name and description are required".into(),
        ));
    }
    let row: Dispute = sqlx::query_as(&format!(
        "INSERT INTO disputes (id, name, email, reason, description, tip_ref, token)
         VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING {DISPUTE_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(req.name.trim())
    .bind(req.email.trim().to_lowercase())
    .bind(req.reason)
    .bind(req.description)
    .bind(req.tip_ref.unwrap_or_default())
    .bind(Uuid::new_v4())
    .fetch_one(&st.pool)
    .await?;

    let reference = format!("TJ-DISP-{}", &row.id.simple().to_string()[..8].to_uppercase());
    Ok(Json(json!({
        "reference": reference,
        "token": row.token,
        "status": row.status,
        "dispute": row,
    })))
}

async fn track_dispute(
    State(st): State<AppState>,
    Path(token): Path<Uuid>,
) -> Result<Json<Dispute>, AppError> {
    let row: Dispute =
        sqlx::query_as(&format!("SELECT {DISPUTE_COLUMNS} FROM disputes WHERE token = $1"))
            .bind(token)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("dispute not found".into()))?;
    Ok(Json(row))
}

async fn list_disputes(State(st): State<AppState>) -> Result<Json<Vec<Dispute>>, AppError> {
    let rows: Vec<Dispute> = sqlx::query_as(&format!(
        "SELECT {DISPUTE_COLUMNS} FROM disputes ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS contact_messages (
            id          UUID PRIMARY KEY,
            name        TEXT NOT NULL,
            email       TEXT NOT NULL DEFAULT '',
            subject     TEXT NOT NULL DEFAULT 'general',
            message     TEXT NOT NULL,
            is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
            created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS disputes (
            id          UUID PRIMARY KEY,
            name        TEXT NOT NULL,
            email       TEXT NOT NULL DEFAULT '',
            reason      TEXT NOT NULL DEFAULT 'other',
            description TEXT NOT NULL,
            tip_ref     TEXT NOT NULL DEFAULT '',
            status      TEXT NOT NULL DEFAULT 'open',
            token       UUID UNIQUE NOT NULL,
            created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS partner_applications (
            id         UUID PRIMARY KEY,
            name       TEXT NOT NULL,
            email      TEXT NOT NULL DEFAULT '',
            company    TEXT NOT NULL DEFAULT '',
            website    TEXT NOT NULL DEFAULT '',
            app_type   TEXT NOT NULL DEFAULT 'partner',
            message    TEXT NOT NULL DEFAULT '',
            status     TEXT NOT NULL DEFAULT 'pending',
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
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

// ── Partner applications ────────────────────────────────────────────────────

#[derive(sqlx::FromRow, Serialize)]
struct PartnerApplication {
    id: Uuid,
    name: String,
    email: String,
    company: String,
    website: String,
    app_type: String,
    message: String,
    status: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

const PARTNER_COLUMNS: &str =
    "id, name, email, company, website, app_type, message, status, created_at";

#[derive(Deserialize)]
struct PartnerReq {
    name: String,
    email: String,
    company: Option<String>,
    website: Option<String>,
    app_type: Option<String>,
    message: Option<String>,
}

async fn create_partner(
    State(st): State<AppState>,
    Json(req): Json<PartnerReq>,
) -> Result<Json<PartnerApplication>, AppError> {
    if req.name.trim().is_empty() {
        return Err(AppError::BadRequest("name is required".into()));
    }
    let row: PartnerApplication = sqlx::query_as(&format!(
        "INSERT INTO partner_applications (id, name, email, company, website, app_type, message)
         VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING {PARTNER_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(req.name.trim())
    .bind(req.email.trim().to_lowercase())
    .bind(req.company.unwrap_or_default())
    .bind(req.website.unwrap_or_default())
    .bind(req.app_type.unwrap_or_else(|| "partner".into()))
    .bind(req.message.unwrap_or_default())
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn list_partners(
    State(st): State<AppState>,
) -> Result<Json<Vec<PartnerApplication>>, AppError> {
    let rows: Vec<PartnerApplication> = sqlx::query_as(&format!(
        "SELECT {PARTNER_COLUMNS} FROM partner_applications ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
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
        "postgres://postgres:postgres@localhost:5432/support_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let app = Router::new()
        .route("/health", get(health))
        .route("/contact", post(create_contact).get(list_contacts))
        .route("/disputes", post(create_dispute).get(list_disputes))
        .route("/disputes/:token", get(track_dispute))
        .route("/partner-apply", post(create_partner).get(list_partners))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(AppState { pool });

    let port = env("PORT", "8088");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("support service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
