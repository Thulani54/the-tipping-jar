//! Payments microservice — fee maths, the transaction ledger, PayCloud (AddPay)
//! hosted-checkout integration, refunds, and a creator payout ledger.
//!
//! PayCloud contract (from the official Java SDK):
//!   POST {gateway}/api/entry  with a flat JSON body of common params
//!   (app_id, method, format=JSON, charset=UTF-8, sign_type=RSA2, version=1.0,
//!   timestamp) + biz fields, plus `sign` = base64(SHA256withRSA over
//!   "k1=v1&k2=v2..." of all non-empty params except `sign`, keys sorted asc).
//!   The private key is PKCS#8; responses are verified with the gateway public
//!   key. `pay.paycloud.checkout` returns `pay_url` to redirect the payer to.

use axum::extract::{Path, State};
use axum::routing::{get, post};
use axum::{Json, Router};
use base64::Engine as _;
use common::{env, AppError};
use rust_decimal::prelude::FromPrimitive;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::collections::BTreeMap;
use uuid::Uuid;

const B64: base64::engine::general_purpose::GeneralPurpose = base64::engine::general_purpose::STANDARD;

// ── PayCloud client ─────────────────────────────────────────────────────────

#[derive(Clone)]
struct PayCloud {
    app_id: String,
    gateway_url: String,
    merchant_no: String,
    currency: String,
    // base64-encoded PKCS#8 private key body (no PEM header). None → disabled.
    private_key_b64: Option<String>,
    http: reqwest::Client,
}

fn value_to_sign_str(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        Value::Null => String::new(),
        other => other.to_string(),
    }
}

impl PayCloud {
    fn enabled(&self) -> bool {
        self.private_key_b64.is_some() && !self.merchant_no.is_empty()
    }

    fn sign(&self, prestr: &str) -> Result<String, AppError> {
        use rsa::pkcs8::DecodePrivateKey;
        use rsa::pkcs1v15::SigningKey;
        use rsa::signature::{SignatureEncoding, Signer};
        use rsa::RsaPrivateKey;
        use sha2::Sha256;

        let b64 = self
            .private_key_b64
            .as_ref()
            .ok_or_else(|| AppError::Internal("PayCloud private key not configured".into()))?;
        let der = B64
            .decode(b64.trim())
            .map_err(|e| AppError::Internal(format!("bad private key base64: {e}")))?;
        let key = RsaPrivateKey::from_pkcs8_der(&der)
            .map_err(|e| AppError::Internal(format!("bad PKCS#8 private key: {e}")))?;
        let signing_key = SigningKey::<Sha256>::new(key);
        let sig = signing_key
            .try_sign(prestr.as_bytes())
            .map_err(|e| AppError::Internal(format!("sign failed: {e}")))?;
        Ok(B64.encode(sig.to_bytes()))
    }

    /// Build common params + biz fields, sign, POST to the gateway, and return
    /// the parsed `data` object on success.
    async fn call(&self, method: &str, biz: Vec<(&str, Value)>) -> Result<Value, AppError> {
        let mut fields: BTreeMap<String, Value> = BTreeMap::new();
        fields.insert("app_id".into(), json!(self.app_id));
        fields.insert("method".into(), json!(method));
        fields.insert("format".into(), json!("JSON"));
        fields.insert("charset".into(), json!("UTF-8"));
        fields.insert("sign_type".into(), json!("RSA2"));
        fields.insert("version".into(), json!("1.0"));
        fields.insert("timestamp".into(), json!(now_millis().to_string()));
        for (k, v) in biz {
            if !v.is_null() {
                fields.insert(k.to_string(), v);
            }
        }

        // Sign string: sorted (BTreeMap), non-empty, excluding `sign`.
        let prestr = fields
            .iter()
            .filter_map(|(k, v)| {
                let s = value_to_sign_str(v);
                if s.is_empty() || k == "sign" {
                    None
                } else {
                    Some(format!("{k}={s}"))
                }
            })
            .collect::<Vec<_>>()
            .join("&");
        let sign = self.sign(&prestr)?;

        let mut body = serde_json::Map::new();
        for (k, v) in &fields {
            body.insert(k.clone(), v.clone());
        }
        body.insert("sign".into(), json!(sign));

        let url = format!("{}/api/entry", self.gateway_url.trim_end_matches('/'));
        let resp = self
            .http
            .post(&url)
            .header("Http-Request-Psn", Uuid::new_v4().simple().to_string())
            .json(&Value::Object(body))
            .send()
            .await?;
        let text = resp.text().await?;
        let parsed: Value = serde_json::from_str(&text)
            .map_err(|_| AppError::Upstream(format!("PayCloud non-JSON response: {text}")))?;

        let code = parsed.get("code").and_then(|c| c.as_str()).unwrap_or("");
        if code != "0" {
            let msg = parsed
                .get("msg")
                .and_then(|m| m.as_str())
                .unwrap_or("unknown error");
            return Err(AppError::Upstream(format!("PayCloud error {code}: {msg}")));
        }
        // `data` is a JSON string that carries the biz response.
        let data = match parsed.get("data") {
            Some(Value::String(s)) => serde_json::from_str(s).unwrap_or_else(|_| json!({})),
            Some(other) => other.clone(),
            None => json!({}),
        };
        Ok(data)
    }
}

fn now_millis() -> i64 {
    chrono::Utc::now().timestamp_millis()
}

// ── State / models ──────────────────────────────────────────────────────────

#[derive(Clone)]
struct AppState {
    pool: PgPool,
    platform_pct: Decimal,
    service_pct: Decimal,
    paycloud: PayCloud,
    // API base that PayCloud posts the notify webhook to (…/payments/notify).
    public_base_url: String,
    // Frontend base the payer is redirected back to (…/payment/callback).
    web_base_url: String,
}

#[derive(sqlx::FromRow, Serialize)]
struct Transaction {
    id: Uuid,
    reference: String,
    creator_id: Uuid,
    amount: Decimal,
    platform_fee: Decimal,
    service_fee: Decimal,
    creator_net: Decimal,
    status: String,
    merchant_order_no: String,
    trans_no: String,
    currency: String,
    pay_url: String,
    description: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

const TXN_COLUMNS: &str = "id, reference, creator_id, amount, platform_fee, service_fee, creator_net, status, merchant_order_no, trans_no, currency, pay_url, description, created_at";

#[derive(sqlx::FromRow, Serialize)]
struct Payout {
    id: Uuid,
    creator_id: Uuid,
    amount: Decimal,
    status: String,
    reference: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

const PAYOUT_COLUMNS: &str = "id, creator_id, amount, status, reference, created_at";

struct Fees {
    platform_fee: Decimal,
    service_fee: Decimal,
    creator_net: Decimal,
}

fn calc_fees(amount: Decimal, platform_pct: Decimal, service_pct: Decimal) -> Fees {
    let hundred = Decimal::from(100);
    let platform_fee = (amount * platform_pct / hundred).round_dp(2);
    let service_fee = (amount * service_pct / hundred).round_dp(2);
    let creator_net = (amount - platform_fee - service_fee).round_dp(2);
    Fees {
        platform_fee,
        service_fee,
        creator_net,
    }
}

fn parse_amount(amount: f64) -> Result<Decimal, AppError> {
    if amount <= 0.0 {
        return Err(AppError::BadRequest("amount must be positive".into()));
    }
    Decimal::from_f64(amount)
        .map(|d| d.round_dp(2))
        .ok_or_else(|| AppError::BadRequest("invalid amount".into()))
}

/// A two-decimal f64 for PayCloud's numeric `order_amount`.
fn amount_2dp(amount: f64) -> f64 {
    (amount * 100.0).round() / 100.0
}

// ── Request bodies ──────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct QuoteReq {
    amount: f64,
}

#[derive(Deserialize)]
struct ChargeReq {
    creator_id: Uuid,
    amount: f64,
    reference: Option<String>,
}

#[derive(Deserialize)]
struct CheckoutReq {
    creator_id: Uuid,
    amount: f64,
    description: Option<String>,
    return_url: Option<String>,
}

#[derive(Deserialize)]
struct RefundReq {
    merchant_order_no: String,
    amount: Option<f64>,
    description: Option<String>,
}

#[derive(Deserialize)]
struct PayoutReq {
    creator_id: Uuid,
    amount: Option<f64>,
}

// ── Handlers ────────────────────────────────────────────────────────────────

async fn health() -> Json<Value> {
    Json(json!({ "status": "ok", "service": "payments" }))
}

async fn quote(
    State(st): State<AppState>,
    Json(req): Json<QuoteReq>,
) -> Result<Json<Value>, AppError> {
    let amount = parse_amount(req.amount)?;
    let f = calc_fees(amount, st.platform_pct, st.service_pct);
    Ok(Json(json!({
        "amount": amount.to_string(),
        "platform_fee": f.platform_fee.to_string(),
        "service_fee": f.service_fee.to_string(),
        "creator_net": f.creator_net.to_string(),
        "total_fee": (f.platform_fee + f.service_fee).to_string(),
        "platform_pct": st.platform_pct.to_string(),
        "service_pct": st.service_pct.to_string(),
        "currency": st.paycloud.currency,
    })))
}

/// Simulated capture (kept for the internal tips flow). Records a completed txn.
async fn charge(
    State(st): State<AppState>,
    Json(req): Json<ChargeReq>,
) -> Result<Json<Transaction>, AppError> {
    let amount = parse_amount(req.amount)?;
    let f = calc_fees(amount, st.platform_pct, st.service_pct);
    let reference = req
        .reference
        .filter(|r| !r.trim().is_empty())
        .unwrap_or_else(|| format!("tj_{}", Uuid::new_v4().simple()));

    let row: Transaction = sqlx::query_as(&format!(
        "INSERT INTO transactions
            (id, reference, creator_id, amount, platform_fee, service_fee, creator_net, status, merchant_order_no, currency)
         VALUES ($1,$2,$3,$4,$5,$6,$7,'completed',$8,$9)
         RETURNING {TXN_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(&reference)
    .bind(req.creator_id)
    .bind(amount)
    .bind(f.platform_fee)
    .bind(f.service_fee)
    .bind(f.creator_net)
    .bind(&reference)
    .bind(&st.paycloud.currency)
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("a transaction with that reference already exists".into())
        }
        _ => e.into(),
    })?;
    Ok(Json(row))
}

/// Real PayCloud hosted checkout — creates a pending transaction and returns the
/// `pay_url` the payer should be redirected to.
async fn checkout(
    State(st): State<AppState>,
    Json(req): Json<CheckoutReq>,
) -> Result<Json<Value>, AppError> {
    if !st.paycloud.enabled() {
        return Err(AppError::Internal(
            "PayCloud is not configured (need PAYCLOUD_PRIVATE_KEY and PAYCLOUD_MERCHANT_NO)".into(),
        ));
    }
    let amount = parse_amount(req.amount)?;
    let f = calc_fees(amount, st.platform_pct, st.service_pct);
    let merchant_order_no = format!("tj{}", Uuid::new_v4().simple());
    let description = req
        .description
        .filter(|d| !d.trim().is_empty())
        .unwrap_or_else(|| "Tipping Jar tip".into());
    let notify_url = format!("{}/payments/notify", st.public_base_url.trim_end_matches('/'));
    let return_url = req
        .return_url
        .filter(|u| !u.trim().is_empty())
        .unwrap_or_else(|| format!("{}/payment/callback", st.web_base_url.trim_end_matches('/')));

    // Persist a pending transaction first so the notify webhook can match it.
    let row: Transaction = sqlx::query_as(&format!(
        "INSERT INTO transactions
            (id, reference, creator_id, amount, platform_fee, service_fee, creator_net, status, merchant_order_no, currency, description)
         VALUES ($1,$2,$3,$4,$5,$6,$7,'pending',$8,$9,$10)
         RETURNING {TXN_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(&merchant_order_no)
    .bind(req.creator_id)
    .bind(amount)
    .bind(f.platform_fee)
    .bind(f.service_fee)
    .bind(f.creator_net)
    .bind(&merchant_order_no)
    .bind(&st.paycloud.currency)
    .bind(&description)
    .fetch_one(&st.pool)
    .await?;

    let data = st
        .paycloud
        .call(
            "pay.paycloud.checkout",
            vec![
                ("merchant_no", json!(st.paycloud.merchant_no)),
                ("merchant_order_no", json!(merchant_order_no)),
                ("price_currency", json!(st.paycloud.currency)),
                ("order_amount", json!(amount_2dp(req.amount))),
                ("description", json!(description)),
                ("notify_url", json!(notify_url)),
                ("return_url", json!(return_url)),
            ],
        )
        .await?;

    let pay_url = data
        .get("pay_url")
        .and_then(|u| u.as_str())
        .unwrap_or("")
        .to_string();
    if pay_url.is_empty() {
        return Err(AppError::Upstream("PayCloud returned no pay_url".into()));
    }
    sqlx::query("UPDATE transactions SET pay_url = $1 WHERE id = $2")
        .bind(&pay_url)
        .bind(row.id)
        .execute(&st.pool)
        .await?;

    Ok(Json(json!({
        "pay_url": pay_url,
        "merchant_order_no": merchant_order_no,
        "reference": merchant_order_no,
        "amount": amount.to_string(),
        "creator_net": f.creator_net.to_string(),
        "status": "pending",
    })))
}

/// PayCloud payment notification webhook (notify_url). Marks the transaction
/// completed. (Signature verification is added once the gateway public key is
/// configured; PayCloud also requires this endpoint to reply "SUCCESS".)
async fn notify(
    State(st): State<AppState>,
    Json(payload): Json<Value>,
) -> Result<String, AppError> {
    tracing::info!("PayCloud notify: {payload}");
    let merchant_order_no = payload
        .get("merchant_order_no")
        .and_then(|v| v.as_str())
        .or_else(|| payload.get("out_trade_no").and_then(|v| v.as_str()))
        .unwrap_or("");
    let trans_no = payload
        .get("trans_no")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let status = payload
        .get("trans_status")
        .or_else(|| payload.get("status"))
        .and_then(|v| v.as_str())
        .unwrap_or("");

    if !merchant_order_no.is_empty() {
        let new_status = if status.eq_ignore_ascii_case("SUCCESS")
            || status.eq_ignore_ascii_case("PAID")
            || status.eq_ignore_ascii_case("COMPLETED")
            || status.is_empty()
        {
            "completed"
        } else {
            "failed"
        };
        sqlx::query(
            "UPDATE transactions SET status = $1, trans_no = COALESCE(NULLIF($2,''), trans_no) WHERE merchant_order_no = $3",
        )
        .bind(new_status)
        .bind(trans_no)
        .bind(merchant_order_no)
        .execute(&st.pool)
        .await?;
    }
    // PayCloud expects a plain "SUCCESS" acknowledgement.
    Ok("SUCCESS".into())
}

async fn order_query(
    State(st): State<AppState>,
    Path(merchant_order_no): Path<String>,
) -> Result<Json<Value>, AppError> {
    if !st.paycloud.enabled() {
        return Err(AppError::Internal("PayCloud not configured".into()));
    }
    let data = st
        .paycloud
        .call(
            "order.query",
            vec![
                ("merchant_no", json!(st.paycloud.merchant_no)),
                ("merchant_order_no", json!(merchant_order_no)),
            ],
        )
        .await?;
    Ok(Json(data))
}

async fn refund(
    State(st): State<AppState>,
    Json(req): Json<RefundReq>,
) -> Result<Json<Value>, AppError> {
    if !st.paycloud.enabled() {
        return Err(AppError::Internal("PayCloud not configured".into()));
    }
    let refund_no = format!("rf{}", Uuid::new_v4().simple());
    let mut biz = vec![
        ("merchant_no", json!(st.paycloud.merchant_no)),
        ("orig_merchant_order_no", json!(req.merchant_order_no)),
        ("merchant_order_no", json!(refund_no)),
        ("price_currency", json!(st.paycloud.currency)),
        (
            "description",
            json!(req.description.unwrap_or_else(|| "Refund".into())),
        ),
    ];
    if let Some(a) = req.amount {
        biz.push(("order_amount", json!(amount_2dp(a))));
    }
    let data = st.paycloud.call("order.refund.submit", biz).await?;
    Ok(Json(json!({ "refund_no": refund_no, "result": data })))
}

async fn get_transaction(
    State(st): State<AppState>,
    Path(reference): Path<String>,
) -> Result<Json<Transaction>, AppError> {
    let row: Transaction = sqlx::query_as(&format!(
        "SELECT {TXN_COLUMNS} FROM transactions WHERE reference = $1 OR merchant_order_no = $1"
    ))
    .bind(reference)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("transaction not found".into()))?;
    Ok(Json(row))
}

async fn creator_balance(
    State(st): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Value>, AppError> {
    let net: (Option<Decimal>, i64) = sqlx::query_as(
        "SELECT COALESCE(SUM(creator_net),0), COUNT(*) FROM transactions WHERE creator_id = $1 AND status = 'completed'",
    )
    .bind(creator_id)
    .fetch_one(&st.pool)
    .await?;
    let paid: (Option<Decimal>,) = sqlx::query_as(
        "SELECT COALESCE(SUM(amount),0) FROM payouts WHERE creator_id = $1 AND status <> 'failed'",
    )
    .bind(creator_id)
    .fetch_one(&st.pool)
    .await?;
    let earned = net.0.unwrap_or_default();
    let withdrawn = paid.0.unwrap_or_default();
    Ok(Json(json!({
        "creator_id": creator_id,
        "net_balance": earned.to_string(),
        "withdrawn": withdrawn.to_string(),
        "available": (earned - withdrawn).to_string(),
        "transaction_count": net.1,
    })))
}

/// Creators view their own transactions.
async fn creator_transactions(
    State(st): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<Transaction>>, AppError> {
    let rows: Vec<Transaction> = sqlx::query_as(&format!(
        "SELECT {TXN_COLUMNS} FROM transactions WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 200"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

/// Request a payout of available balance. Records a ledger entry (prevents
/// over-withdrawal). The actual bank transfer runs via PayCloud settlement /
/// profit-sharing once creator receiver details are configured.
async fn request_payout(
    State(st): State<AppState>,
    Json(req): Json<PayoutReq>,
) -> Result<Json<Payout>, AppError> {
    let net: (Option<Decimal>,) = sqlx::query_as(
        "SELECT COALESCE(SUM(creator_net),0) FROM transactions WHERE creator_id = $1 AND status = 'completed'",
    )
    .bind(req.creator_id)
    .fetch_one(&st.pool)
    .await?;
    let paid: (Option<Decimal>,) = sqlx::query_as(
        "SELECT COALESCE(SUM(amount),0) FROM payouts WHERE creator_id = $1 AND status <> 'failed'",
    )
    .bind(req.creator_id)
    .fetch_one(&st.pool)
    .await?;
    let available = net.0.unwrap_or_default() - paid.0.unwrap_or_default();

    let amount = match req.amount {
        Some(a) => parse_amount(a)?,
        None => available,
    };
    if amount <= Decimal::ZERO {
        return Err(AppError::BadRequest("nothing available to pay out".into()));
    }
    if amount > available {
        return Err(AppError::BadRequest(format!(
            "requested {amount} exceeds available balance {available}"
        )));
    }
    let reference = format!("po_{}", Uuid::new_v4().simple());
    let row: Payout = sqlx::query_as(&format!(
        "INSERT INTO payouts (id, creator_id, amount, status, reference)
         VALUES ($1,$2,$3,'pending',$4) RETURNING {PAYOUT_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(req.creator_id)
    .bind(amount)
    .bind(&reference)
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn creator_payouts(
    State(st): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<Payout>>, AppError> {
    let rows: Vec<Payout> = sqlx::query_as(&format!(
        "SELECT {PAYOUT_COLUMNS} FROM payouts WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 200"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

// ── Bootstrap ───────────────────────────────────────────────────────────────

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS transactions (
            id                UUID PRIMARY KEY,
            reference         TEXT UNIQUE NOT NULL,
            creator_id        UUID NOT NULL,
            amount            NUMERIC(12,2) NOT NULL,
            platform_fee      NUMERIC(12,2) NOT NULL DEFAULT 0,
            service_fee       NUMERIC(12,2) NOT NULL DEFAULT 0,
            creator_net       NUMERIC(12,2) NOT NULL DEFAULT 0,
            status            TEXT NOT NULL DEFAULT 'pending',
            merchant_order_no TEXT NOT NULL DEFAULT '',
            trans_no          TEXT NOT NULL DEFAULT '',
            currency          TEXT NOT NULL DEFAULT 'ZAR',
            pay_url           TEXT NOT NULL DEFAULT '',
            description       TEXT NOT NULL DEFAULT '',
            created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    // Add PayCloud columns to a pre-existing transactions table.
    for col in [
        "merchant_order_no TEXT NOT NULL DEFAULT ''",
        "trans_no TEXT NOT NULL DEFAULT ''",
        "currency TEXT NOT NULL DEFAULT 'ZAR'",
        "pay_url TEXT NOT NULL DEFAULT ''",
        "description TEXT NOT NULL DEFAULT ''",
    ] {
        sqlx::query(&format!(
            "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS {col}"
        ))
        .execute(pool)
        .await?;
    }
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_txn_creator ON transactions (creator_id)")
        .execute(pool)
        .await?;
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_txn_mono ON transactions (merchant_order_no)")
        .execute(pool)
        .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS payouts (
            id         UUID PRIMARY KEY,
            creator_id UUID NOT NULL,
            amount     NUMERIC(12,2) NOT NULL,
            status     TEXT NOT NULL DEFAULT 'pending',
            reference  TEXT NOT NULL DEFAULT '',
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

fn pct_env(key: &str, default: f64) -> Decimal {
    let raw = env(key, &default.to_string());
    raw.parse::<f64>()
        .ok()
        .and_then(Decimal::from_f64)
        .unwrap_or_else(|| Decimal::from_f64(default).unwrap())
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
        "postgres://postgres:postgres@localhost:5432/payments_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let private_key = env("PAYCLOUD_PRIVATE_KEY", "");
    let paycloud = PayCloud {
        app_id: env("PAYCLOUD_APP_ID", "wzd89ec0d57dbd8170"),
        gateway_url: env("PAYCLOUD_GATEWAY_URL", "https://addpay-op.wangtest.cn"),
        merchant_no: env("PAYCLOUD_MERCHANT_NO", ""),
        currency: env("PAYCLOUD_CURRENCY", "ZAR"),
        private_key_b64: if private_key.trim().is_empty() {
            None
        } else {
            Some(private_key)
        },
        http: reqwest::Client::new(),
    };
    tracing::info!(
        "PayCloud enabled = {} (app_id set, merchant_no {}, gateway {})",
        paycloud.enabled(),
        if paycloud.merchant_no.is_empty() { "MISSING" } else { "set" },
        paycloud.gateway_url,
    );

    let state = AppState {
        pool,
        platform_pct: pct_env("PLATFORM_FEE_PERCENT", 3.0),
        service_pct: pct_env("SERVICE_FEE_PERCENT", 3.0),
        paycloud,
        public_base_url: env("PUBLIC_BASE_URL", "http://localhost:8083"),
        web_base_url: env("WEB_BASE_URL", "http://localhost:3000"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/payments/quote", post(quote))
        .route("/payments/charge", post(charge))
        .route("/payments/checkout", post(checkout))
        .route("/payments/notify", post(notify))
        .route("/payments/refund", post(refund))
        .route("/payments/order/:merchant_order_no", get(order_query))
        .route("/payments/payout", post(request_payout))
        .route("/payments/creator/:creator_id/balance", get(creator_balance))
        .route(
            "/payments/creator/:creator_id/transactions",
            get(creator_transactions),
        )
        .route("/payments/creator/:creator_id/payouts", get(creator_payouts))
        .route("/payments/:reference", get(get_transaction))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8083");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("payments service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
