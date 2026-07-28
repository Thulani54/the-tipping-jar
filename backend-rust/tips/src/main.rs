//! Tips microservice — the orchestrator.
//!
//! Creating a tip fans out to two other services:
//!   1. creators  (`CREATORS_URL`) — resolve & validate the target creator
//!   2. payments  (`PAYMENTS_URL`) — capture the money and compute the fee split
//! then it persists a tip row with the fee snapshot returned by payments.

use axum::extract::{Path, State};
use axum::http::HeaderMap;
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
    creators_url: String,
    payments_url: String,
    scheduler_url: String,
}

#[derive(sqlx::FromRow, Serialize)]
struct Tip {
    id: Uuid,
    creator_id: Uuid,
    creator_name: String,
    tipper_name: String,
    tipper_email: String,
    amount: Decimal,
    message: String,
    status: String,
    reference: String,
    platform_fee: Decimal,
    service_fee: Decimal,
    creator_net: Decimal,
    thanks_message: String,
    thanked_at: Option<chrono::DateTime<chrono::Utc>>,
    created_at: chrono::DateTime<chrono::Utc>,
}

const TIP_COLUMNS: &str = "id, creator_id, creator_name, tipper_name, tipper_email, amount, message, status, reference, platform_fee, service_fee, creator_net, thanks_message, thanked_at, created_at";

#[derive(sqlx::FromRow, Serialize)]
struct Pledge {
    id: Uuid,
    creator_id: Uuid,
    tier_id: Option<Uuid>,
    fan_name: String,
    fan_email: String,
    amount: Decimal,
    status: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

const PLEDGE_COLUMNS: &str =
    "id, creator_id, tier_id, fan_name, fan_email, amount, status, created_at";

// ── Shapes returned by the services we call ─────────────────────────────────

#[derive(Deserialize)]
struct CreatorResp {
    id: Uuid,
    display_name: String,
    is_active: bool,
}

#[derive(Deserialize)]
struct ChargeResp {
    reference: String,
    status: String,
    platform_fee: Decimal,
    service_fee: Decimal,
    creator_net: Decimal,
}

// ── Request body ────────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct TipReq {
    /// Either identify the creator by slug (public) or by id (internal).
    creator_slug: Option<String>,
    creator_id: Option<Uuid>,
    amount: f64,
    tipper_name: Option<String>,
    tipper_email: Option<String>,
    message: Option<String>,
}

// ── Handlers ────────────────────────────────────────────────────────────────

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "tips" }))
}

/// Resolve the target creator via the creators service.
async fn resolve_creator(st: &AppState, req: &TipReq) -> Result<CreatorResp, AppError> {
    let url = if let Some(slug) = req.creator_slug.as_deref().filter(|s| !s.is_empty()) {
        format!("{}/creators/{}", st.creators_url, slug)
    } else if let Some(id) = req.creator_id {
        format!("{}/internal/creators/{}", st.creators_url, id)
    } else {
        return Err(AppError::BadRequest(
            "provide creator_slug or creator_id".into(),
        ));
    };

    let resp = st.http.get(&url).send().await?;
    if resp.status().as_u16() == 404 {
        return Err(AppError::NotFound("creator not found".into()));
    }
    if !resp.status().is_success() {
        return Err(AppError::Upstream("creators service error".into()));
    }
    let creator: CreatorResp = resp.json().await?;
    if !creator.is_active {
        return Err(AppError::BadRequest(
            "creator is not accepting tips".into(),
        ));
    }
    Ok(creator)
}

/// Capture the payment via the payments service.
async fn capture_payment(
    st: &AppState,
    creator_id: Uuid,
    amount: f64,
) -> Result<ChargeResp, AppError> {
    let resp = st
        .http
        .post(format!("{}/payments/charge", st.payments_url))
        .json(&json!({ "creator_id": creator_id, "amount": amount }))
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Upstream("payment capture failed".into()));
    }
    Ok(resp.json().await?)
}

async fn create_tip(
    State(st): State<AppState>,
    Json(req): Json<TipReq>,
) -> Result<Json<Tip>, AppError> {
    if req.amount <= 0.0 {
        return Err(AppError::BadRequest("amount must be positive".into()));
    }

    // 1) tips -> creators
    let creator = resolve_creator(&st, &req).await?;
    // 2) tips -> payments
    let charge = capture_payment(&st, creator.id, req.amount).await?;

    let amount = Decimal::try_from(req.amount)
        .map(|d| d.round_dp(2))
        .map_err(|_| AppError::BadRequest("invalid amount".into()))?;
    let status = if charge.status == "completed" {
        "completed"
    } else {
        "pending"
    };

    // 3) persist the tip with the fee snapshot from payments
    let row: Tip = sqlx::query_as(&format!(
        "INSERT INTO tips
            (id, creator_id, creator_name, tipper_name, tipper_email, amount, message,
             status, reference, platform_fee, service_fee, creator_net)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
         RETURNING {TIP_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(creator.id)
    .bind(&creator.display_name)
    .bind(req.tipper_name.unwrap_or_else(|| "Anonymous".into()))
    .bind(req.tipper_email.unwrap_or_default())
    .bind(amount)
    .bind(req.message.unwrap_or_default())
    .bind(status)
    .bind(&charge.reference)
    .bind(charge.platform_fee)
    .bind(charge.service_fee)
    .bind(charge.creator_net)
    .fetch_one(&st.pool)
    .await?;

    Ok(Json(row))
}

/// Public feed of recent completed tips.
async fn list_tips(State(st): State<AppState>) -> Result<Json<Vec<Tip>>, AppError> {
    let rows: Vec<Tip> = sqlx::query_as(&format!(
        "SELECT {TIP_COLUMNS} FROM tips WHERE status = 'completed' ORDER BY created_at DESC LIMIT 50"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

/// Resolve the caller's creator id via the creators service (`/creators/me`),
/// requiring it to match `creator_id`.
async fn require_owner(
    st: &AppState,
    headers: &HeaderMap,
    creator_id: Uuid,
) -> Result<(), AppError> {
    let auth = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or_else(|| AppError::Unauthorized("missing bearer token".into()))?;
    let resp = st
        .http
        .get(format!("{}/creators/me", st.creators_url))
        .header(axum::http::header::AUTHORIZATION, auth)
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Unauthorized("no creator profile for this user".into()));
    }
    let body: serde_json::Value = resp.json().await?;
    let mine = body
        .get("id")
        .and_then(|v| v.as_str())
        .and_then(|s| Uuid::parse_str(s).ok())
        .ok_or_else(|| AppError::Unauthorized("bad creators response".into()))?;
    if mine != creator_id {
        return Err(AppError::Unauthorized("not your creator account".into()));
    }
    Ok(())
}

/// The creator's supporters, aggregated across completed tips (owner-only).
async fn supporters_for_creator(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<serde_json::Value>>, AppError> {
    require_owner(&st, &headers, creator_id).await?;
    let rows: Vec<(String, String, i64, Decimal, chrono::DateTime<chrono::Utc>)> = sqlx::query_as(
        "SELECT COALESCE(NULLIF(tipper_email,''), tipper_name) AS key,
                MAX(tipper_name), count(*), COALESCE(SUM(amount),0), MAX(created_at)
         FROM tips WHERE creator_id = $1 AND status = 'completed'
         GROUP BY key ORDER BY 4 DESC LIMIT 100",
    )
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(
        rows.into_iter()
            .map(|(key, name, count, total, last)| {
                let email = if key.contains('@') { key } else { String::new() };
                serde_json::json!({
                    "name": name, "email": email, "tip_count": count,
                    "total": total.to_string(), "last_tip_at": last,
                })
            })
            .collect(),
    ))
}

#[derive(Deserialize)]
struct ThankReq {
    message: String,
}

/// Creator thanks a tipper: stores the note on the tip and (when the tipper
/// left an email) sends it via the scheduler's SMTP.
async fn thank_tip(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
    Json(req): Json<ThankReq>,
) -> Result<Json<Tip>, AppError> {
    let msg = req.message.trim().to_string();
    if msg.is_empty() || msg.len() > 500 {
        return Err(AppError::BadRequest("message must be 1–500 characters".into()));
    }
    let tip: Tip = sqlx::query_as(&format!("SELECT {TIP_COLUMNS} FROM tips WHERE id = $1"))
        .bind(id)
        .fetch_optional(&st.pool)
        .await?
        .ok_or_else(|| AppError::NotFound("tip not found".into()))?;
    require_owner(&st, &headers, tip.creator_id).await?;

    let updated: Tip = sqlx::query_as(&format!(
        "UPDATE tips SET thanks_message = $1, thanked_at = now() WHERE id = $2 RETURNING {TIP_COLUMNS}"
    ))
    .bind(&msg)
    .bind(id)
    .fetch_one(&st.pool)
    .await?;

    if !updated.tipper_email.is_empty() {
        let body = serde_json::json!({
            "to": updated.tipper_email,
            "tipper_name": updated.tipper_name,
            "creator_name": updated.creator_name,
            "amount": updated.amount.to_string(),
            "message": msg,
        });
        if let Err(e) = st
            .http
            .post(format!("{}/internal/send-thanks", st.scheduler_url))
            .json(&body)
            .send()
            .await
        {
            tracing::warn!("thanks email for tip {id} failed to send: {e}");
        }
    }
    Ok(Json(updated))
}

/// The creator's own tip volume per day, last 30 days (owner-only).
async fn creator_daily_stats(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<serde_json::Value>>, AppError> {
    require_owner(&st, &headers, creator_id).await?;
    let rows: Vec<(chrono::NaiveDate, i64, Decimal, Decimal)> = sqlx::query_as(
        "SELECT (created_at AT TIME ZONE 'Africa/Johannesburg')::date AS day,
                count(*), COALESCE(SUM(amount),0), COALESCE(SUM(creator_net),0)
         FROM tips
         WHERE creator_id = $1 AND status = 'completed' AND created_at > now() - interval '30 days'
         GROUP BY day ORDER BY day",
    )
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(
        rows.into_iter()
            .map(|(day, count, gross, net)| {
                serde_json::json!({ "day": day.to_string(), "count": count, "gross": gross.to_string(), "net": net.to_string() })
            })
            .collect(),
    ))
}

#[derive(Deserialize)]
struct MessageSupportersReq {
    subject: String,
    message: String,
}

/// Creator emails an update to every supporter who left an email address.
async fn message_supporters(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(creator_id): Path<Uuid>,
    Json(req): Json<MessageSupportersReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    require_owner(&st, &headers, creator_id).await?;
    if req.subject.trim().is_empty() || req.message.trim().is_empty() {
        return Err(AppError::BadRequest("subject and message are required".into()));
    }
    let emails: Vec<(String,)> = sqlx::query_as(
        "SELECT DISTINCT lower(tipper_email) FROM tips
         WHERE creator_id = $1 AND status = 'completed' AND tipper_email <> ''",
    )
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    if emails.is_empty() {
        return Err(AppError::BadRequest(
            "none of your supporters left an email address yet".into(),
        ));
    }
    let name: Option<(String,)> = sqlx::query_as(
        "SELECT creator_name FROM tips WHERE creator_id = $1 AND creator_name <> '' LIMIT 1",
    )
    .bind(creator_id)
    .fetch_optional(&st.pool)
    .await?;
    let creator_name = name.map(|n| n.0).unwrap_or_else(|| "your creator".into());

    let body = serde_json::json!({
        "subject": format!("{} · update from {}", req.subject.trim(), creator_name),
        "message": req.message,
        "audience": "custom",
        "recipients": emails.into_iter().map(|e| e.0).collect::<Vec<_>>(),
        "actor": format!("creator:{creator_name}"),
    });
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

/// Internal (admin portal): latest tips across every status. Key-guarded.
async fn list_tips_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<Tip>>, AppError> {
    common::require_internal_key(&headers)?;
    let rows: Vec<Tip> = sqlx::query_as(&format!(
        "SELECT {TIP_COLUMNS} FROM tips ORDER BY created_at DESC LIMIT 150"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

/// Internal (admin portal): completed-tip volume per day, last 30 days (SAST).
async fn daily_stats_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<serde_json::Value>>, AppError> {
    common::require_internal_key(&headers)?;
    let rows: Vec<(chrono::NaiveDate, i64, Decimal, Decimal)> = sqlx::query_as(
        "SELECT (created_at AT TIME ZONE 'Africa/Johannesburg')::date AS day,
                count(*), COALESCE(SUM(amount),0), COALESCE(SUM(creator_net),0)
         FROM tips
         WHERE status = 'completed' AND created_at > now() - interval '30 days'
         GROUP BY day ORDER BY day",
    )
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(
        rows.into_iter()
            .map(|(day, count, gross, net)| {
                serde_json::json!({
                    "day": day.to_string(),
                    "count": count,
                    "gross": gross.to_string(),
                    "net": net.to_string(),
                })
            })
            .collect(),
    ))
}

async fn tips_for_creator(
    State(st): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<Tip>>, AppError> {
    let rows: Vec<Tip> = sqlx::query_as(&format!(
        "SELECT {TIP_COLUMNS} FROM tips WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 200"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

// ── Pledges, stats, fan history ─────────────────────────────────────────────

#[derive(Deserialize)]
struct PledgeReq {
    creator_slug: Option<String>,
    creator_id: Option<Uuid>,
    amount: f64,
    fan_name: Option<String>,
    fan_email: Option<String>,
    tier_id: Option<Uuid>,
}

async fn resolve_creator_for_pledge(
    st: &AppState,
    req: &PledgeReq,
) -> Result<CreatorResp, AppError> {
    let url = if let Some(slug) = req.creator_slug.as_deref().filter(|s| !s.is_empty()) {
        format!("{}/creators/{}", st.creators_url, slug)
    } else if let Some(id) = req.creator_id {
        format!("{}/internal/creators/{}", st.creators_url, id)
    } else {
        return Err(AppError::BadRequest(
            "provide creator_slug or creator_id".into(),
        ));
    };
    let resp = st.http.get(&url).send().await?;
    if resp.status().as_u16() == 404 {
        return Err(AppError::NotFound("creator not found".into()));
    }
    if !resp.status().is_success() {
        return Err(AppError::Upstream("creators service error".into()));
    }
    Ok(resp.json().await?)
}

async fn create_pledge(
    State(st): State<AppState>,
    Json(req): Json<PledgeReq>,
) -> Result<Json<Pledge>, AppError> {
    if req.amount <= 0.0 {
        return Err(AppError::BadRequest("amount must be positive".into()));
    }
    let creator = resolve_creator_for_pledge(&st, &req).await?;
    let amount = Decimal::try_from(req.amount)
        .map(|d| d.round_dp(2))
        .map_err(|_| AppError::BadRequest("invalid amount".into()))?;
    let row: Pledge = sqlx::query_as(&format!(
        "INSERT INTO pledges (id, creator_id, tier_id, fan_name, fan_email, amount)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING {PLEDGE_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(creator.id)
    .bind(req.tier_id)
    .bind(req.fan_name.unwrap_or_else(|| "Anonymous".into()))
    .bind(req.fan_email.unwrap_or_default())
    .bind(amount)
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn pledges_for_creator(
    State(st): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<Pledge>>, AppError> {
    let rows: Vec<Pledge> = sqlx::query_as(&format!(
        "SELECT {PLEDGE_COLUMNS} FROM pledges WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 200"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

/// Aggregate tip stats for a creator dashboard.
async fn creator_stats(
    State(st): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    let row: (Option<Decimal>, i64, i64, Option<Decimal>, Option<Decimal>) = sqlx::query_as(
        "SELECT COALESCE(SUM(amount),0), COUNT(*), \
         COUNT(DISTINCT NULLIF(lower(tipper_email),'')), \
         COALESCE(SUM(creator_net),0), \
         COALESCE(SUM(amount) FILTER (WHERE date_trunc('month',created_at)=date_trunc('month',now())),0) \
         FROM tips WHERE creator_id = $1 AND status = 'completed'",
    )
    .bind(creator_id)
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(json!({
        "creator_id": creator_id,
        "total_amount": row.0.unwrap_or_default().to_string(),
        "tip_count": row.1,
        "supporter_count": row.2,
        "creator_net_total": row.3.unwrap_or_default().to_string(),
        "this_month_amount": row.4.unwrap_or_default().to_string(),
    })))
}

/// Tips sent by a fan (by email) — for the fan dashboard.
async fn tips_for_fan(
    State(st): State<AppState>,
    Path(email): Path<String>,
) -> Result<Json<Vec<Tip>>, AppError> {
    let rows: Vec<Tip> = sqlx::query_as(&format!(
        "SELECT {TIP_COLUMNS} FROM tips WHERE lower(tipper_email) = lower($1) ORDER BY created_at DESC LIMIT 200"
    ))
    .bind(email)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

// ── Internal: record a completed tip (called by the payments service) ───────

#[derive(Deserialize)]
struct RecordReq {
    creator_id: Uuid,
    creator_name: Option<String>,
    tipper_name: Option<String>,
    tipper_email: Option<String>,
    amount: String,
    message: Option<String>,
    reference: String,
    platform_fee: Option<String>,
    service_fee: Option<String>,
    creator_net: Option<String>,
}

fn dec(s: &Option<String>) -> Decimal {
    s.as_deref()
        .and_then(|v| v.parse::<Decimal>().ok())
        .unwrap_or_default()
}

async fn record_tip(
    State(st): State<AppState>,
    Json(req): Json<RecordReq>,
) -> Result<Json<Tip>, AppError> {
    // Idempotent by reference — a webhook can fire more than once.
    if let Some(existing) = sqlx::query_as::<_, Tip>(&format!(
        "SELECT {TIP_COLUMNS} FROM tips WHERE reference = $1"
    ))
    .bind(&req.reference)
    .fetch_optional(&st.pool)
    .await?
    {
        return Ok(Json(existing));
    }
    let amount = req.amount.parse::<Decimal>().unwrap_or_default().round_dp(2);
    let row: Tip = sqlx::query_as(&format!(
        "INSERT INTO tips
            (id, creator_id, creator_name, tipper_name, tipper_email, amount, message,
             status, reference, platform_fee, service_fee, creator_net)
         VALUES ($1,$2,$3,$4,$5,$6,$7,'completed',$8,$9,$10,$11)
         RETURNING {TIP_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(req.creator_id)
    .bind(req.creator_name.unwrap_or_default())
    .bind(req.tipper_name.unwrap_or_else(|| "Anonymous".into()))
    .bind(req.tipper_email.unwrap_or_default())
    .bind(amount)
    .bind(req.message.unwrap_or_default())
    .bind(&req.reference)
    .bind(dec(&req.platform_fee))
    .bind(dec(&req.service_fee))
    .bind(dec(&req.creator_net))
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

// ── Bootstrap ───────────────────────────────────────────────────────────────

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS tips (
            id           UUID PRIMARY KEY,
            creator_id   UUID NOT NULL,
            creator_name TEXT NOT NULL DEFAULT '',
            tipper_name  TEXT NOT NULL DEFAULT 'Anonymous',
            tipper_email TEXT NOT NULL DEFAULT '',
            amount       NUMERIC(10,2) NOT NULL,
            message      TEXT NOT NULL DEFAULT '',
            status       TEXT NOT NULL DEFAULT 'pending',
            reference    TEXT NOT NULL DEFAULT '',
            platform_fee NUMERIC(10,2) NOT NULL DEFAULT 0,
            service_fee  NUMERIC(10,2) NOT NULL DEFAULT 0,
            creator_net  NUMERIC(10,2) NOT NULL DEFAULT 0,
            created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_tips_creator ON tips (creator_id)")
        .execute(pool)
        .await?;
    // Thank-you replies (added later — migrate existing databases).
    sqlx::query("ALTER TABLE tips ADD COLUMN IF NOT EXISTS thanks_message TEXT NOT NULL DEFAULT ''")
        .execute(pool)
        .await?;
    sqlx::query("ALTER TABLE tips ADD COLUMN IF NOT EXISTS thanked_at TIMESTAMPTZ")
        .execute(pool)
        .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS pledges (
            id         UUID PRIMARY KEY,
            creator_id UUID NOT NULL,
            tier_id    UUID,
            fan_name   TEXT NOT NULL DEFAULT 'Anonymous',
            fan_email  TEXT NOT NULL DEFAULT '',
            amount     NUMERIC(10,2) NOT NULL,
            status     TEXT NOT NULL DEFAULT 'active',
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_pledges_creator ON pledges (creator_id)")
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
        "postgres://postgres:postgres@localhost:5432/tips_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let state = AppState {
        pool,
        http: reqwest::Client::new(),
        creators_url: env("CREATORS_URL", "http://localhost:8082"),
        payments_url: env("PAYMENTS_URL", "http://localhost:8083"),
        scheduler_url: env("SCHEDULER_URL", "http://localhost:8092"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/tips", post(create_tip).get(list_tips))
        .route("/tips/pledges", post(create_pledge))
        .route("/tips/pledges/creator/:creator_id", get(pledges_for_creator))
        .route("/tips/creator/:creator_id", get(tips_for_creator))
        .route("/tips/creator/:creator_id/supporters", get(supporters_for_creator))
        .route("/tips/creator/:creator_id/stats/daily", get(creator_daily_stats))
        .route("/tips/creator/:creator_id/message-supporters", post(message_supporters))
        .route("/tips/:id/thanks", post(thank_tip))
        .route("/tips/creator/:creator_id/stats", get(creator_stats))
        .route("/tips/fan/:email", get(tips_for_fan))
        .route("/tips/internal/record", post(record_tip))
        .route("/internal/tips/recent", get(list_tips_internal))
        .route("/internal/tips/stats/daily", get(daily_stats_internal))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8084");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("tips service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
