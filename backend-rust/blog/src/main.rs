//! Blog microservice — owns blog posts (ports the Django `blog` app).

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

fn bearer(headers: &HeaderMap) -> Result<String, AppError> {
    let raw = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or_else(|| AppError::Unauthorized("missing Authorization header".into()))?;
    raw.strip_prefix("Bearer ")
        .map(|t| t.to_string())
        .ok_or_else(|| AppError::Unauthorized("expected 'Bearer <token>'".into()))
}

/// Require the caller's token to belong to an admin (verified via accounts).
async fn require_admin(st: &AppState, token: &str) -> Result<(), AppError> {
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
    if body.get("role").and_then(|r| r.as_str()) != Some("admin") {
        return Err(AppError::Unauthorized("admin access required".into()));
    }
    Ok(())
}

#[derive(sqlx::FromRow, Serialize)]
struct Post {
    id: Uuid,
    title: String,
    slug: String,
    category: String,
    excerpt: String,
    content: String,
    author_name: String,
    read_time: String,
    is_published: bool,
    created_at: chrono::DateTime<chrono::Utc>,
    updated_at: chrono::DateTime<chrono::Utc>,
}

const POST_COLUMNS: &str = "id, title, slug, category, excerpt, content, author_name, read_time, is_published, created_at, updated_at";

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
        out.push_str("post");
    }
    out
}

#[derive(Deserialize)]
struct CreateReq {
    title: String,
    excerpt: String,
    content: String,
    category: Option<String>,
    author_name: Option<String>,
    read_time: Option<String>,
    is_published: Option<bool>,
    slug: Option<String>,
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "blog" }))
}

async fn create_post(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<CreateReq>,
) -> Result<Json<Post>, AppError> {
    require_admin(&st, &bearer(&headers)?).await?;
    if req.title.trim().is_empty() {
        return Err(AppError::BadRequest("title is required".into()));
    }
    let slug = req
        .slug
        .filter(|s| !s.trim().is_empty())
        .map(|s| slugify(&s))
        .unwrap_or_else(|| slugify(&req.title));

    let row: Post = sqlx::query_as(&format!(
        "INSERT INTO blog_posts
            (id, title, slug, category, excerpt, content, author_name, read_time, is_published)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING {POST_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(req.title.trim())
    .bind(&slug)
    .bind(req.category.unwrap_or_else(|| "creator-guide".into()))
    .bind(req.excerpt)
    .bind(req.content)
    .bind(req.author_name.unwrap_or_else(|| "TippingJar Team".into()))
    .bind(req.read_time.unwrap_or_else(|| "5 min read".into()))
    .bind(req.is_published.unwrap_or(false))
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("a post with that slug already exists".into())
        }
        _ => e.into(),
    })?;
    Ok(Json(row))
}

async fn list_posts(State(st): State<AppState>) -> Result<Json<Vec<Post>>, AppError> {
    let rows: Vec<Post> = sqlx::query_as(&format!(
        "SELECT {POST_COLUMNS} FROM blog_posts WHERE is_published = TRUE ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn get_post(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<Post>, AppError> {
    let row: Post =
        sqlx::query_as(&format!("SELECT {POST_COLUMNS} FROM blog_posts WHERE slug = $1"))
            .bind(slug)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("post not found".into()))?;
    Ok(Json(row))
}

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS blog_posts (
            id           UUID PRIMARY KEY,
            title        TEXT NOT NULL,
            slug         TEXT UNIQUE NOT NULL,
            category     TEXT NOT NULL DEFAULT 'creator-guide',
            excerpt      TEXT NOT NULL DEFAULT '',
            content      TEXT NOT NULL DEFAULT '',
            author_name  TEXT NOT NULL DEFAULT 'TippingJar Team',
            read_time    TEXT NOT NULL DEFAULT '5 min read',
            is_published BOOLEAN NOT NULL DEFAULT FALSE,
            created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
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
        "postgres://postgres:postgres@localhost:5432/blog_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let app = Router::new()
        .route("/health", get(health))
        .route("/posts", post(create_post).get(list_posts))
        .route("/posts/:slug", get(get_post))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(AppState {
            pool,
            http: reqwest::Client::new(),
            accounts_url: env("ACCOUNTS_URL", "http://localhost:8081"),
        });

    let port = env("PORT", "8085");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("blog service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
