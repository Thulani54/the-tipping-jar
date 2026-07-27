//! Admin portal microservice — the platform's admin API.
//!
//! Owns no database. Every request is authenticated as an **admin** (JWT role
//! check via the accounts service), then fanned out to the other services'
//! internal endpoints (shared INTERNAL_KEY header) to read and manage users,
//! creators, tips, transactions, payouts and support inboxes.

use axum::extract::{Path, State};
use axum::http::{header::AUTHORIZATION, HeaderMap};
use axum::routing::{get, post};
use axum::{Json, Router};
use common::{env, AppError};
use serde_json::{json, Value};

#[derive(Clone)]
struct AppState {
    http: reqwest::Client,
    accounts_url: String,
    creators_url: String,
    tips_url: String,
    support_url: String,
    payments_url: String,
    internal_key: String,
}

async fn health() -> Json<Value> {
    Json(json!({ "status": "ok", "service": "admin_portal" }))
}

// ── Auth ────────────────────────────────────────────────────────────────────

/// Verify the caller's bearer token with accounts and require the admin role.
async fn require_admin(st: &AppState, headers: &HeaderMap) -> Result<String, AppError> {
    let token = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or_else(|| AppError::Unauthorized("missing bearer token".into()))?;
    let resp = st
        .http
        .post(format!("{}/internal/verify-token", st.accounts_url))
        .json(&json!({ "token": token }))
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Unauthorized("invalid token".into()));
    }
    let body: Value = resp.json().await?;
    let role = body.get("role").and_then(|r| r.as_str()).unwrap_or("");
    if role != "admin" {
        return Err(AppError::Unauthorized("admin access required".into()));
    }
    Ok(body
        .get("user_id")
        .and_then(|u| u.as_str())
        .unwrap_or_default()
        .to_string())
}

// ── Service fan-out helpers ─────────────────────────────────────────────────

async fn fetch_json(st: &AppState, url: String, with_key: bool) -> Result<Value, String> {
    let mut req = st.http.get(&url);
    if with_key {
        req = req.header("x-internal-key", &st.internal_key);
    }
    let resp = req.send().await.map_err(|e| format!("request failed: {e}"))?;
    if !resp.status().is_success() {
        return Err(format!("status {}", resp.status()));
    }
    resp.json().await.map_err(|e| format!("bad json: {e}"))
}

async fn fetch_array(st: &AppState, url: String, with_key: bool) -> Vec<Value> {
    fetch_json(st, url, with_key)
        .await
        .ok()
        .and_then(|v| v.as_array().cloned())
        .unwrap_or_default()
}

fn num(v: &Value, key: &str) -> f64 {
    v.get(key)
        .map(|a| match a {
            Value::String(s) => s.parse::<f64>().unwrap_or(0.0),
            Value::Number(n) => n.as_f64().unwrap_or(0.0),
            _ => 0.0,
        })
        .unwrap_or(0.0)
}

fn is_status(v: &Value, status: &str) -> bool {
    v.get("status").and_then(|s| s.as_str()) == Some(status)
}

// ── Endpoints ───────────────────────────────────────────────────────────────

/// The admin overview: totals + recent activity across the whole platform.
async fn dashboard(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;

    let (users, creators, tips, txns, payouts, contacts, disputes) = tokio::join!(
        fetch_array(&st, format!("{}/internal/users", st.accounts_url), true),
        fetch_array(&st, format!("{}/internal/creators/all", st.creators_url), true),
        fetch_array(&st, format!("{}/internal/tips/recent", st.tips_url), true),
        fetch_array(&st, format!("{}/internal/transactions", st.payments_url), true),
        fetch_array(&st, format!("{}/internal/payouts", st.payments_url), true),
        fetch_array(&st, format!("{}/contact", st.support_url), false),
        fetch_array(&st, format!("{}/disputes", st.support_url), false),
    );

    let completed: Vec<&Value> = tips.iter().filter(|t| is_status(t, "completed")).collect();
    let gross: f64 = completed.iter().map(|t| num(t, "amount")).sum();
    let net: f64 = completed.iter().map(|t| num(t, "creator_net")).sum();
    let pending_payouts: Vec<&Value> =
        payouts.iter().filter(|p| is_status(p, "pending")).collect();
    let pending_amount: f64 = pending_payouts.iter().map(|p| num(p, "amount")).sum();

    Ok(Json(json!({
        "totals": {
            "users": users.len(),
            "creators": creators.len(),
            "creators_active": creators.iter().filter(|c| c.get("is_active").and_then(|b| b.as_bool()).unwrap_or(false)).count(),
            "tips": tips.len(),
            "tips_completed": completed.len(),
            "gross_volume": format!("{gross:.2}"),
            "creator_net": format!("{net:.2}"),
            "transactions": txns.len(),
            "payouts_pending": pending_payouts.len(),
            "payouts_pending_amount": format!("{pending_amount:.2}"),
            "contacts": contacts.len(),
            "disputes": disputes.len(),
        },
        "recent_tips": tips.into_iter().take(8).collect::<Vec<_>>(),
        "recent_transactions": txns.into_iter().take(8).collect::<Vec<_>>(),
    })))
}

async fn users(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(Value::Array(
        fetch_array(&st, format!("{}/internal/users", st.accounts_url), true).await,
    )))
}

async fn creators(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(Value::Array(
        fetch_array(&st, format!("{}/internal/creators/all", st.creators_url), true).await,
    )))
}

async fn tips(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(Value::Array(
        fetch_array(&st, format!("{}/internal/tips/recent", st.tips_url), true).await,
    )))
}

async fn transactions(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(Value::Array(
        fetch_array(&st, format!("{}/internal/transactions", st.payments_url), true).await,
    )))
}

async fn payouts(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(Value::Array(
        fetch_array(&st, format!("{}/internal/payouts", st.payments_url), true).await,
    )))
}

/// Support inboxes: contact messages, disputes and partner applications.
async fn tickets(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    let (contacts, disputes, partners) = tokio::join!(
        fetch_array(&st, format!("{}/contact", st.support_url), false),
        fetch_array(&st, format!("{}/disputes", st.support_url), false),
        fetch_array(&st, format!("{}/partner-apply", st.support_url), false),
    );
    Ok(Json(json!({
        "contacts": contacts,
        "disputes": disputes,
        "partners": partners,
    })))
}

async fn set_creator_active(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    let resp = st
        .http
        .post(format!("{}/internal/creators/{id}/active", st.creators_url))
        .header("x-internal-key", &st.internal_key)
        .json(&body)
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Upstream(format!("creators: {}", resp.status())));
    }
    Ok(Json(resp.json().await?))
}

async fn set_payout_status(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    let resp = st
        .http
        .post(format!("{}/internal/payouts/{id}/status", st.payments_url))
        .header("x-internal-key", &st.internal_key)
        .json(&body)
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Upstream(format!("payments: {}", resp.status())));
    }
    Ok(Json(resp.json().await?))
}

// ── Bootstrap ───────────────────────────────────────────────────────────────

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let state = AppState {
        http: reqwest::Client::new(),
        accounts_url: env("ACCOUNTS_URL", "http://localhost:8081"),
        creators_url: env("CREATORS_URL", "http://localhost:8082"),
        tips_url: env("TIPS_URL", "http://localhost:8084"),
        support_url: env("SUPPORT_URL", "http://localhost:8088"),
        payments_url: env("PAYMENTS_URL", "http://localhost:8083"),
        internal_key: env("INTERNAL_KEY", "tj-internal-dev-key"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/dashboard", get(dashboard))
        .route("/users", get(users))
        .route("/creators", get(creators))
        .route("/creators/:id/active", post(set_creator_active))
        .route("/tips", get(tips))
        .route("/transactions", get(transactions))
        .route("/payouts", get(payouts))
        .route("/payouts/:id/status", post(set_payout_status))
        .route("/tickets", get(tickets))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8091");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("admin_portal service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
