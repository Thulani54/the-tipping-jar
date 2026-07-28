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
    scheduler_url: String,
    platform_url: String,
    internal_key: String,
}

async fn health() -> Json<Value> {
    Json(json!({ "status": "ok", "service": "admin_portal" }))
}

// ── Auth ────────────────────────────────────────────────────────────────────

/// Verify the caller's bearer token with accounts and require the admin role.
/// Returns (user_id, email) for audit trails.
async fn require_admin(st: &AppState, headers: &HeaderMap) -> Result<(String, String), AppError> {
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
    Ok((
        body.get("user_id").and_then(|u| u.as_str()).unwrap_or_default().to_string(),
        body.get("email").and_then(|u| u.as_str()).unwrap_or_default().to_string(),
    ))
}

/// Fire-and-forget audit record in the platform service.
async fn audit(st: &AppState, actor: &str, action: &str, target: &str, detail: &str) {
    let body = json!({ "actor": actor, "action": action, "target": target, "detail": detail });
    let _ = st
        .http
        .post(format!("{}/internal/audit", st.platform_url))
        .header("x-internal-key", &st.internal_key)
        .json(&body)
        .send()
        .await;
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

/// Generic proxy for an internal POST/DELETE mutation on another service.
async fn forward(
    st: &AppState,
    method: reqwest::Method,
    url: String,
    body: Option<&Value>,
) -> Result<Json<Value>, AppError> {
    let mut req = st
        .http
        .request(method, &url)
        .header("x-internal-key", &st.internal_key);
    if let Some(b) = body {
        req = req.json(b);
    }
    let resp = req.send().await?;
    if !resp.status().is_success() {
        return Err(AppError::Upstream(format!("{url}: {}", resp.status())));
    }
    Ok(Json(resp.json().await.unwrap_or(json!({ "ok": true }))))
}

/// Completed-tip volume per day, last 30 days — powers the overview chart.
async fn analytics_daily(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(Value::Array(
        fetch_array(&st, format!("{}/internal/tips/stats/daily", st.tips_url), true).await,
    )))
}

async fn set_user_role(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    let (_, email) = require_admin(&st, &headers).await?;
    audit(&st, &email, "user.set_role", &id, &body.to_string()).await;
    forward(&st, reqwest::Method::POST, format!("{}/internal/users/{id}/role", st.accounts_url), Some(&body)).await
}

async fn delete_user(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<Value>, AppError> {
    let (admin_id, admin_email) = require_admin(&st, &headers).await?;
    if admin_id == id {
        return Err(AppError::BadRequest("you cannot delete your own account".into()));
    }
    audit(&st, &admin_email, "user.delete", &id, "").await;
    forward(&st, reqwest::Method::DELETE, format!("{}/internal/users/{id}", st.accounts_url), None).await
}

async fn set_creator_kyc(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    let (_, email) = require_admin(&st, &headers).await?;
    audit(&st, &email, "creator.set_kyc", &id, &body.to_string()).await;
    forward(&st, reqwest::Method::POST, format!("{}/internal/creators/{id}/kyc", st.creators_url), Some(&body)).await
}

async fn delete_creator(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<Value>, AppError> {
    let (_, email) = require_admin(&st, &headers).await?;
    audit(&st, &email, "creator.delete", &id, "").await;
    forward(&st, reqwest::Method::DELETE, format!("{}/internal/creators/{id}", st.creators_url), None).await
}

async fn set_dispute_status(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    let (_, email) = require_admin(&st, &headers).await?;
    audit(&st, &email, "dispute.set_status", &id, &body.to_string()).await;
    forward(&st, reqwest::Method::POST, format!("{}/internal/disputes/{id}/status", st.support_url), Some(&body)).await
}

/// Ops: run the nightly report now (optionally for ?date=YYYY-MM-DD).
async fn run_daily_report(
    State(st): State<AppState>,
    headers: HeaderMap,
    axum::extract::Query(q): axum::extract::Query<Value>,
) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    let date = q.get("date").and_then(|d| d.as_str()).unwrap_or("");
    let url = if date.is_empty() {
        format!("{}/internal/run-daily-report", st.scheduler_url)
    } else {
        format!("{}/internal/run-daily-report?date={date}", st.scheduler_url)
    };
    let resp = st.http.post(&url).send().await?;
    if !resp.status().is_success() {
        return Err(AppError::Upstream(format!("scheduler: {}", resp.status())));
    }
    Ok(Json(resp.json().await?))
}

/// Ops: run the signup-completion reminder sweep now.
async fn run_signup_reminders(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    let resp = st
        .http
        .post(format!("{}/internal/run-signup-reminders", st.scheduler_url))
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Upstream(format!("scheduler: {}", resp.status())));
    }
    Ok(Json(resp.json().await?))
}

async fn set_creator_active(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    let (_, email) = require_admin(&st, &headers).await?;
    audit(&st, &email, "creator.set_active", &id, &body.to_string()).await;
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
    let (_, email) = require_admin(&st, &headers).await?;
    audit(&st, &email, "payout.set_status", &id, &body.to_string()).await;
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

async fn set_creator_featured(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    let (_, email) = require_admin(&st, &headers).await?;
    audit(&st, &email, "creator.set_featured", &id, &body.to_string()).await;
    forward(&st, reqwest::Method::POST, format!("{}/internal/creators/{id}/featured", st.creators_url), Some(&body)).await
}

/// Broadcast an announcement email via the scheduler's SMTP.
async fn broadcast(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<Value>,
) -> Result<Json<Value>, AppError> {
    let (_, email) = require_admin(&st, &headers).await?;
    let subject = body.get("subject").and_then(|s| s.as_str()).unwrap_or("").to_string();
    let audience = body.get("audience").and_then(|s| s.as_str()).unwrap_or("creators").to_string();
    audit(&st, &email, "comms.broadcast", &subject, &audience).await;
    let mut body = body;
    if let Some(obj) = body.as_object_mut() {
        obj.insert("actor".into(), json!(email));
    }
    let resp = st
        .http
        .post(format!("{}/internal/broadcast", st.scheduler_url))
        .json(&body)
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Upstream(format!("scheduler: {}", resp.status())));
    }
    Ok(Json(resp.json().await?))
}

/// Fleet status: ping every service's /health with a short timeout.
async fn system(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    let targets: Vec<(String, String)> = vec![
        ("accounts".into(), st.accounts_url.clone()),
        ("creators".into(), st.creators_url.clone()),
        ("tips".into(), st.tips_url.clone()),
        ("payments".into(), st.payments_url.clone()),
        ("support".into(), st.support_url.clone()),
        ("platform".into(), st.platform_url.clone()),
        ("scheduler".into(), st.scheduler_url.clone()),
        ("blog".into(), "http://blog:8085".into()),
        ("careers".into(), "http://careers:8086".into()),
        ("enterprise".into(), "http://enterprise:8087".into()),
        ("referrals".into(), "http://referrals:8089".into()),
    ];
    let mut handles = Vec::new();
    for (name, base) in targets {
        let http = st.http.clone();
        handles.push(tokio::spawn(async move {
            let ok = matches!(
                http.get(format!("{base}/health"))
                    .timeout(std::time::Duration::from_secs(3))
                    .send()
                    .await,
                Ok(r) if r.status().is_success()
            );
            json!({ "service": name, "ok": ok })
        }));
    }
    let mut results = Vec::new();
    for h in handles {
        results.push(h.await.unwrap_or_else(|_| json!({ "service": "?", "ok": false })));
    }
    Ok(Json(Value::Array(results)))
}

/// Comms history from the scheduler's log.
async fn comms_log(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(
        fetch_json(&st, format!("{}/internal/comms-log", st.scheduler_url), false)
            .await
            .unwrap_or(Value::Array(vec![])),
    ))
}

/// The admin action trail.
async fn audit_list(State(st): State<AppState>, headers: HeaderMap) -> Result<Json<Value>, AppError> {
    require_admin(&st, &headers).await?;
    Ok(Json(
        fetch_json(&st, format!("{}/internal/audit", st.platform_url), true)
            .await
            .unwrap_or(Value::Array(vec![])),
    ))
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
        scheduler_url: env("SCHEDULER_URL", "http://localhost:8092"),
        platform_url: env("PLATFORM_URL", "http://localhost:8090"),
        internal_key: env("INTERNAL_KEY", "tj-internal-dev-key"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/dashboard", get(dashboard))
        .route("/users", get(users))
        .route("/users/:id", axum::routing::delete(delete_user))
        .route("/users/:id/role", post(set_user_role))
        .route("/creators", get(creators))
        .route("/creators/:id", axum::routing::delete(delete_creator))
        .route("/creators/:id/active", post(set_creator_active))
        .route("/creators/:id/kyc", post(set_creator_kyc))
        .route("/tips", get(tips))
        .route("/analytics/daily", get(analytics_daily))
        .route("/transactions", get(transactions))
        .route("/payouts", get(payouts))
        .route("/payouts/:id/status", post(set_payout_status))
        .route("/tickets", get(tickets))
        .route("/disputes/:id/status", post(set_dispute_status))
        .route("/ops/daily-report", post(run_daily_report))
        .route("/ops/signup-reminders", post(run_signup_reminders))
        .route("/creators/:id/featured", post(set_creator_featured))
        .route("/broadcast", post(broadcast))
        .route("/comms-log", get(comms_log))
        .route("/system", get(system))
        .route("/audit", get(audit_list))
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
