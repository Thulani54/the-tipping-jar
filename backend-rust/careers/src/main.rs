//! Careers microservice — owns job openings (ports the Django `careers` app).

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
struct Job {
    id: Uuid,
    title: String,
    department: String,
    location: String,
    employment_type: String,
    description: String,
    is_active: bool,
    created_at: chrono::DateTime<chrono::Utc>,
    updated_at: chrono::DateTime<chrono::Utc>,
}

const JOB_COLUMNS: &str =
    "id, title, department, location, employment_type, description, is_active, created_at, updated_at";

#[derive(Deserialize)]
struct CreateReq {
    title: String,
    department: Option<String>,
    location: Option<String>,
    employment_type: Option<String>,
    description: Option<String>,
    is_active: Option<bool>,
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "careers" }))
}

async fn create_job(
    State(st): State<AppState>,
    Json(req): Json<CreateReq>,
) -> Result<Json<Job>, AppError> {
    if req.title.trim().is_empty() {
        return Err(AppError::BadRequest("title is required".into()));
    }
    let row: Job = sqlx::query_as(&format!(
        "INSERT INTO job_openings
            (id, title, department, location, employment_type, description, is_active)
         VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING {JOB_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(req.title.trim())
    .bind(req.department.unwrap_or_else(|| "Engineering".into()))
    .bind(req.location.unwrap_or_else(|| "Remote".into()))
    .bind(req.employment_type.unwrap_or_else(|| "Full-time".into()))
    .bind(req.description.unwrap_or_default())
    .bind(req.is_active.unwrap_or(true))
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn list_jobs(State(st): State<AppState>) -> Result<Json<Vec<Job>>, AppError> {
    let rows: Vec<Job> = sqlx::query_as(&format!(
        "SELECT {JOB_COLUMNS} FROM job_openings WHERE is_active = TRUE ORDER BY department, title"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn get_job(
    State(st): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Job>, AppError> {
    let row: Job = sqlx::query_as(&format!("SELECT {JOB_COLUMNS} FROM job_openings WHERE id = $1"))
        .bind(id)
        .fetch_optional(&st.pool)
        .await?
        .ok_or_else(|| AppError::NotFound("job not found".into()))?;
    Ok(Json(row))
}

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS job_openings (
            id              UUID PRIMARY KEY,
            title           TEXT NOT NULL,
            department      TEXT NOT NULL DEFAULT 'Engineering',
            location        TEXT NOT NULL DEFAULT 'Remote',
            employment_type TEXT NOT NULL DEFAULT 'Full-time',
            description     TEXT NOT NULL DEFAULT '',
            is_active       BOOLEAN NOT NULL DEFAULT TRUE,
            created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
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
        "postgres://postgres:postgres@localhost:5432/careers_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let app = Router::new()
        .route("/health", get(health))
        .route("/jobs", post(create_job).get(list_jobs))
        .route("/jobs/:id", get(get_job))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(AppState { pool });

    let port = env("PORT", "8086");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("careers service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
