//! Accounts microservice — the identity provider for the Tipping Jar fleet.
//!
//! Owns users and issues JWTs. Other services never see the signing secret;
//! they verify a token by POSTing it to `/internal/verify-token`.

use argon2::password_hash::SaltString;
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use axum::extract::{Path, State};
use axum::http::{header::AUTHORIZATION, HeaderMap};
use axum::routing::{get, post};
use axum::{Json, Router};
use common::{env, jwt, AppError};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Clone)]
struct AppState {
    pool: PgPool,
    jwt_secret: String,
}

// ── Data model ──────────────────────────────────────────────────────────────

#[derive(sqlx::FromRow)]
struct UserRow {
    id: Uuid,
    email: String,
    username: String,
    role: String,
    phone_number: String,
    two_fa_enabled: bool,
    is_minor: bool,
    referral_code_used: String,
    password_hash: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Serialize)]
struct UserOut {
    id: Uuid,
    email: String,
    username: String,
    role: String,
    phone_number: String,
    two_fa_enabled: bool,
    is_minor: bool,
    referral_code_used: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

impl UserRow {
    fn to_out(&self) -> UserOut {
        UserOut {
            id: self.id,
            email: self.email.clone(),
            username: self.username.clone(),
            role: self.role.clone(),
            phone_number: self.phone_number.clone(),
            two_fa_enabled: self.two_fa_enabled,
            is_minor: self.is_minor,
            referral_code_used: self.referral_code_used.clone(),
            created_at: self.created_at,
        }
    }
}

const USER_COLUMNS: &str =
    "id, email, username, role, phone_number, two_fa_enabled, is_minor, referral_code_used, password_hash, created_at";

#[derive(sqlx::FromRow)]
struct OtpRow {
    id: Uuid,
    code: String,
    expires_at: chrono::DateTime<chrono::Utc>,
}

// ── Password hashing (Argon2id) ─────────────────────────────────────────────

fn hash_password(pw: &str) -> Result<String, AppError> {
    // Derive a 16-byte salt from a v4 UUID so we don't depend on argon2's
    // optional RNG feature.
    let salt_bytes = Uuid::new_v4().into_bytes();
    let salt = SaltString::encode_b64(&salt_bytes)
        .map_err(|e| AppError::Internal(format!("salt error: {e}")))?;
    let hash = Argon2::default()
        .hash_password(pw.as_bytes(), &salt)
        .map_err(|e| AppError::Internal(format!("hash error: {e}")))?;
    Ok(hash.to_string())
}

fn verify_password(pw: &str, hash: &str) -> Result<(), AppError> {
    let parsed =
        PasswordHash::new(hash).map_err(|e| AppError::Internal(format!("hash parse: {e}")))?;
    Argon2::default()
        .verify_password(pw.as_bytes(), &parsed)
        .map_err(|_| AppError::Unauthorized("invalid credentials".into()))
}

fn is_unique_violation(e: &sqlx::Error) -> bool {
    matches!(e, sqlx::Error::Database(db) if db.code().as_deref() == Some("23505"))
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

// ── Request / response bodies ───────────────────────────────────────────────

#[derive(Deserialize)]
struct RegisterReq {
    email: String,
    username: Option<String>,
    password: String,
    role: Option<String>,
    phone_number: Option<String>,
    referral_code: Option<String>,
}

#[derive(Deserialize)]
struct LoginReq {
    email: String,
    password: String,
}

#[derive(Serialize)]
struct AuthResp {
    token: String,
    user: UserOut,
}

#[derive(Deserialize)]
struct VerifyReq {
    token: String,
}

#[derive(Serialize)]
struct VerifyResp {
    user_id: String,
    email: String,
    role: String,
}

#[derive(Deserialize)]
struct VerifyOtpReq {
    code: String,
}

#[derive(Deserialize)]
struct TwoFaReq {
    enabled: bool,
}

// ── Handlers ────────────────────────────────────────────────────────────────

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "accounts" }))
}

async fn register(
    State(st): State<AppState>,
    Json(req): Json<RegisterReq>,
) -> Result<Json<AuthResp>, AppError> {
    if req.password.len() < 6 {
        return Err(AppError::BadRequest(
            "password must be at least 6 characters".into(),
        ));
    }
    let email = req.email.trim().to_lowercase();
    if !email.contains('@') {
        return Err(AppError::BadRequest("invalid email".into()));
    }
    let username = req
        .username
        .filter(|u| !u.trim().is_empty())
        .unwrap_or_else(|| email.split('@').next().unwrap_or("user").to_string());
    // Only fan/creator may be self-assigned at signup — never admin/enterprise
    // (those are provisioned out of band). Prevents privilege escalation.
    let role = match req.role.as_deref() {
        Some("creator") => "creator",
        _ => "fan",
    }
    .to_string();
    let phone = req.phone_number.unwrap_or_default();
    let referral = req.referral_code.unwrap_or_default();
    let hash = hash_password(&req.password)?;

    let row: UserRow = sqlx::query_as(&format!(
        "INSERT INTO users (id, email, username, password_hash, role, phone_number, referral_code_used)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING {USER_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(&email)
    .bind(&username)
    .bind(&hash)
    .bind(&role)
    .bind(&phone)
    .bind(&referral)
    .fetch_one(&st.pool)
    .await
    .map_err(|e| {
        if is_unique_violation(&e) {
            AppError::Conflict("an account with that email already exists".into())
        } else {
            e.into()
        }
    })?;

    let token = jwt::encode_jwt(
        &row.id.to_string(),
        &row.email,
        &row.role,
        &st.jwt_secret,
        60 * 60 * 24,
    )?;
    Ok(Json(AuthResp {
        token,
        user: row.to_out(),
    }))
}

async fn login(
    State(st): State<AppState>,
    Json(req): Json<LoginReq>,
) -> Result<Json<AuthResp>, AppError> {
    let email = req.email.trim().to_lowercase();
    let row: UserRow =
        sqlx::query_as(&format!("SELECT {USER_COLUMNS} FROM users WHERE email = $1"))
            .bind(&email)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::Unauthorized("invalid credentials".into()))?;

    verify_password(&req.password, &row.password_hash)?;

    let token = jwt::encode_jwt(
        &row.id.to_string(),
        &row.email,
        &row.role,
        &st.jwt_secret,
        60 * 60 * 24,
    )?;
    Ok(Json(AuthResp {
        token,
        user: row.to_out(),
    }))
}

async fn me(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<UserOut>, AppError> {
    let token = bearer(&headers)?;
    let claims = jwt::decode_jwt(&token, &st.jwt_secret)?;
    let id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::Unauthorized("malformed subject".into()))?;
    let row: UserRow =
        sqlx::query_as(&format!("SELECT {USER_COLUMNS} FROM users WHERE id = $1"))
            .bind(id)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("user no longer exists".into()))?;
    Ok(Json(row.to_out()))
}

/// Internal: verify a JWT for another service and confirm the user still exists.
async fn verify_token(
    State(st): State<AppState>,
    Json(req): Json<VerifyReq>,
) -> Result<Json<VerifyResp>, AppError> {
    let claims = jwt::decode_jwt(&req.token, &st.jwt_secret)?;
    let id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::Unauthorized("malformed subject".into()))?;
    let exists: Option<(Uuid,)> = sqlx::query_as("SELECT id FROM users WHERE id = $1")
        .bind(id)
        .fetch_optional(&st.pool)
        .await?;
    if exists.is_none() {
        return Err(AppError::Unauthorized("user no longer exists".into()));
    }
    Ok(Json(VerifyResp {
        user_id: claims.sub,
        email: claims.email,
        role: claims.role,
    }))
}

/// Internal: fetch a user by id (used by the creators service).
async fn get_user(
    State(st): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<UserOut>, AppError> {
    let row: UserRow =
        sqlx::query_as(&format!("SELECT {USER_COLUMNS} FROM users WHERE id = $1"))
            .bind(id)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("user not found".into()))?;
    Ok(Json(row.to_out()))
}

// ── OTP / two-factor ────────────────────────────────────────────────────────

fn user_from_bearer(st: &AppState, headers: &HeaderMap) -> Result<Uuid, AppError> {
    let token = bearer(headers)?;
    let claims = jwt::decode_jwt(&token, &st.jwt_secret)?;
    Uuid::parse_str(&claims.sub).map_err(|_| AppError::Unauthorized("malformed subject".into()))
}

/// Generate and "send" a one-time code. The code is logged server-side (until a
/// real email/SMS provider is wired) and is NEVER returned in the response.
async fn request_otp(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<serde_json::Value>, AppError> {
    let user_id = user_from_bearer(&st, &headers)?;
    sqlx::query("UPDATE otps SET is_used = TRUE WHERE user_id = $1 AND is_used = FALSE")
        .bind(user_id)
        .execute(&st.pool)
        .await?;
    let code = format!(
        "{:06}",
        (u128::from_be_bytes(*Uuid::new_v4().as_bytes()) % 1_000_000) as u32
    );
    let expires_at = chrono::Utc::now() + chrono::Duration::minutes(10);
    sqlx::query("INSERT INTO otps (id, user_id, code, method, expires_at) VALUES ($1, $2, $3, 'email', $4)")
        .bind(Uuid::new_v4())
        .bind(user_id)
        .bind(&code)
        .bind(expires_at)
        .execute(&st.pool)
        .await?;
    tracing::info!("OTP for user {user_id}: {code}");
    Ok(Json(json!({ "sent": true, "method": "email" })))
}

async fn verify_otp(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<VerifyOtpReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    let user_id = user_from_bearer(&st, &headers)?;
    let otp: OtpRow = sqlx::query_as(
        "SELECT id, code, expires_at FROM otps WHERE user_id = $1 AND is_used = FALSE ORDER BY created_at DESC LIMIT 1",
    )
    .bind(user_id)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::Unauthorized("no active code — request a new one".into()))?;

    if otp.code != req.code.trim() || otp.expires_at <= chrono::Utc::now() {
        return Err(AppError::Unauthorized("invalid or expired code".into()));
    }
    sqlx::query("UPDATE otps SET is_used = TRUE WHERE id = $1")
        .bind(otp.id)
        .execute(&st.pool)
        .await?;
    Ok(Json(json!({ "verified": true })))
}

async fn set_2fa(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<TwoFaReq>,
) -> Result<Json<UserOut>, AppError> {
    let user_id = user_from_bearer(&st, &headers)?;
    let row: UserRow = sqlx::query_as(&format!(
        "UPDATE users SET two_fa_enabled = $1 WHERE id = $2 RETURNING {USER_COLUMNS}"
    ))
    .bind(req.enabled)
    .bind(user_id)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("user not found".into()))?;
    Ok(Json(row.to_out()))
}

// ── Bootstrap ───────────────────────────────────────────────────────────────

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS users (
            id                 UUID PRIMARY KEY,
            email              TEXT UNIQUE NOT NULL,
            username           TEXT NOT NULL,
            password_hash      TEXT NOT NULL,
            role               TEXT NOT NULL DEFAULT 'fan',
            phone_number       TEXT NOT NULL DEFAULT '',
            two_fa_enabled     BOOLEAN NOT NULL DEFAULT FALSE,
            is_minor           BOOLEAN NOT NULL DEFAULT FALSE,
            referral_code_used TEXT NOT NULL DEFAULT '',
            created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS otps (
            id         UUID PRIMARY KEY,
            user_id    UUID NOT NULL,
            code       TEXT NOT NULL,
            method     TEXT NOT NULL DEFAULT 'email',
            is_used    BOOLEAN NOT NULL DEFAULT FALSE,
            expires_at TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    Ok(())
}

async fn connect_with_retry(db_url: &str) -> PgPool {
    for attempt in 1..=30 {
        match PgPoolOptions::new()
            .max_connections(5)
            .connect(db_url)
            .await
        {
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
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let db_url = env(
        "DATABASE_URL",
        "postgres://postgres:postgres@localhost:5432/accounts_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let state = AppState {
        pool,
        jwt_secret: env("JWT_SECRET", "dev-secret-change-me"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/auth/register", post(register))
        .route("/auth/login", post(login))
        .route("/auth/me", get(me))
        .route("/auth/request-otp", post(request_otp))
        .route("/auth/verify-otp", post(verify_otp))
        .route("/auth/2fa", post(set_2fa))
        .route("/internal/verify-token", post(verify_token))
        .route("/internal/users/:id", get(get_user))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8081");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("accounts service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
