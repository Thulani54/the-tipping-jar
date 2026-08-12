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
use axum::http::{header::AUTHORIZATION, HeaderMap};
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
    // base64 X.509/SPKI gateway public key, used to verify notify + responses.
    gateway_public_key_b64: Option<String>,
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

    /// Verify a signed payload (e.g. the notify webhook) with the gateway public
    /// key. Returns false when no key is configured or the signature is
    /// missing/invalid — callers MUST treat false as "reject" (fail closed).
    fn verify(&self, payload: &serde_json::Map<String, Value>) -> bool {
        use rsa::pkcs1v15::{Signature, VerifyingKey};
        use rsa::pkcs8::DecodePublicKey;
        use rsa::signature::Verifier;
        use rsa::RsaPublicKey;
        use sha2::Sha256;

        let Some(pub_b64) = self.gateway_public_key_b64.as_ref() else {
            return false;
        };
        let sign = match payload.get("sign").and_then(|s| s.as_str()) {
            Some(s) if !s.is_empty() => s,
            _ => return false,
        };
        let prestr = payload
            .iter()
            .filter_map(|(k, v)| {
                let s = value_to_sign_str(v);
                if s.is_empty() || k == "sign" {
                    None
                } else {
                    Some((k.clone(), s))
                }
            })
            .collect::<BTreeMap<_, _>>()
            .iter()
            .map(|(k, v)| format!("{k}={v}"))
            .collect::<Vec<_>>()
            .join("&");

        let Ok(der) = B64.decode(pub_b64.trim()) else {
            return false;
        };
        let Ok(pk) = RsaPublicKey::from_public_key_der(&der) else {
            return false;
        };
        let Ok(sig_bytes) = B64.decode(sign) else {
            return false;
        };
        let Ok(sig) = Signature::try_from(sig_bytes.as_slice()) else {
            return false;
        };
        VerifyingKey::<Sha256>::new(pk)
            .verify(prestr.as_bytes(), &sig)
            .is_ok()
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
    http: reqwest::Client,
    accounts_url: String,
    creators_url: String,
    tips_url: String,
}

// ── Auth (delegated to the accounts + creators services) ────────────────────

fn bearer(headers: &HeaderMap) -> Result<String, AppError> {
    let raw = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or_else(|| AppError::Unauthorized("missing Authorization header".into()))?;
    raw.strip_prefix("Bearer ")
        .map(|t| t.to_string())
        .ok_or_else(|| AppError::Unauthorized("expected 'Bearer <token>'".into()))
}

/// Verify a JWT via the accounts service, returning (user_id, role).
async fn verify_token(st: &AppState, token: &str) -> Result<(String, String), AppError> {
    let resp = st
        .http
        .post(format!("{}/internal/verify-token", st.accounts_url))
        .json(&json!({ "token": token }))
        .send()
        .await?;
    if !resp.status().is_success() {
        return Err(AppError::Unauthorized("invalid token".into()));
    }
    let b: Value = resp.json().await?;
    let uid = b
        .get("user_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| AppError::Internal("accounts returned no user id".into()))?
        .to_string();
    let role = b
        .get("role")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    Ok((uid, role))
}

/// The caller's own creator-profile id (via creators `/creators/me`), or None.
async fn my_creator_id(st: &AppState, token: &str) -> Result<Option<Uuid>, AppError> {
    let resp = st
        .http
        .get(format!("{}/creators/me", st.creators_url))
        .bearer_auth(token)
        .send()
        .await?;
    if resp.status().as_u16() == 404 {
        return Ok(None);
    }
    if !resp.status().is_success() {
        return Err(AppError::Unauthorized("token rejected".into()));
    }
    let b: Value = resp.json().await?;
    let id = b
        .get("id")
        .and_then(|v| v.as_str())
        .and_then(|s| Uuid::parse_str(s).ok());
    Ok(id)
}

/// Require that the caller owns `creator_id` (or is an admin).
async fn require_creator_owner(
    st: &AppState,
    headers: &HeaderMap,
    creator_id: Uuid,
) -> Result<(), AppError> {
    let token = bearer(headers)?;
    let (_uid, role) = verify_token(st, &token).await?;
    if role == "admin" {
        return Ok(());
    }
    match my_creator_id(st, &token).await? {
        Some(mine) if mine == creator_id => Ok(()),
        _ => Err(AppError::Unauthorized("not your creator account".into())),
    }
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
    creator_name: String,
    tipper_name: String,
    tipper_email: String,
    message: String,
    jar_id: Option<Uuid>,
    created_at: chrono::DateTime<chrono::Utc>,
}

const TXN_COLUMNS: &str = "id, reference, creator_id, amount, platform_fee, service_fee, creator_net, status, merchant_order_no, trans_no, currency, pay_url, description, creator_name, tipper_name, tipper_email, message, jar_id, created_at";

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
    tipper_name: Option<String>,
    tipper_email: Option<String>,
    message: Option<String>,
    jar_id: Option<Uuid>,
}

#[derive(Deserialize)]
struct RefundReq {
    merchant_order_no: String,
    amount: Option<f64>,
    description: Option<String>,
}

#[derive(Deserialize)]
struct PayoutReq {
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
    if req.amount < min_tip() {
        return Err(AppError::BadRequest(format!(
            "minimum tip is R{:.0} (card processing costs)", min_tip()
        )));
    }
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
    if req.amount < min_tip() {
        return Err(AppError::BadRequest(format!(
            "minimum tip is R{:.0} (card processing costs)", min_tip()
        )));
    }
    if !st.paycloud.enabled() {
        return Err(AppError::Internal(
            "PayCloud is not configured (need PAYCLOUD_PRIVATE_KEY and PAYCLOUD_MERCHANT_NO)".into(),
        ));
    }
    // The payer may be anonymous, but the payee creator must exist.
    let cr = st
        .http
        .get(format!(
            "{}/internal/creators/{}",
            st.creators_url, req.creator_id
        ))
        .send()
        .await?;
    if !cr.status().is_success() {
        return Err(AppError::BadRequest("creator not found".into()));
    }
    let creator_json: Value = cr.json().await.unwrap_or_else(|_| json!({}));
    let creator_name = creator_json
        .get("display_name")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();

    let amount = parse_amount(req.amount)?;
    let f = calc_fees(amount, st.platform_pct, st.service_pct);
    // PayCloud caps the order number length — keep it short (prefix + 22 hex).
    let merchant_order_no = format!("tj{}", &Uuid::new_v4().simple().to_string()[..22]);
    let description = req
        .description
        .filter(|d| !d.trim().is_empty())
        .unwrap_or_else(|| "Tipping Jar tip".into());
    let notify_url = format!("{}/payments/notify", st.public_base_url.trim_end_matches('/'));
    // Only honour a client return_url that points at our own frontend
    // (open-redirect guard); otherwise use the default callback.
    let default_return = format!("{}/payment/callback", st.web_base_url.trim_end_matches('/'));
    let base_return = req
        .return_url
        .filter(|u| u.starts_with(&st.web_base_url))
        .unwrap_or(default_return);
    // Always inject the merchant_order_no as `ref` on the return URL so the
    // callback page can identify the transaction even when PayCloud drops
    // its own query params on the redirect.
    let sep = if base_return.contains('?') { '&' } else { '?' };
    let return_url = format!("{base_return}{sep}ref={merchant_order_no}");

    // Persist a pending transaction first so the notify webhook can match it.
    let row: Transaction = sqlx::query_as(&format!(
        "INSERT INTO transactions
            (id, reference, creator_id, amount, platform_fee, service_fee, creator_net, status, merchant_order_no, currency, description, creator_name, tipper_name, tipper_email, message, jar_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,'pending',$8,$9,$10,$11,$12,$13,$14,$15)
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
    .bind(&creator_name)
    .bind(req.tipper_name.clone().unwrap_or_else(|| "Anonymous".into()))
    .bind(req.tipper_email.clone().unwrap_or_default())
    .bind(req.message.clone().unwrap_or_default())
    .bind(req.jar_id)
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
    Json(payload): Json<serde_json::Map<String, Value>>,
) -> Result<String, AppError> {
    let merchant_order_no = payload
        .get("merchant_order_no")
        .and_then(|v| v.as_str())
        .or_else(|| payload.get("out_trade_no").and_then(|v| v.as_str()))
        .unwrap_or("")
        .to_string();
    let trans_no = payload
        .get("trans_no")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    // PayCloud trans_status is an INTEGER: 2=successful, 1=closed, 3=cancelled,
    // 0=paying, 9=created. (Accept a string form too, defensively.)
    let trans_status = payload
        .get("trans_status")
        .and_then(|v| v.as_i64().or_else(|| v.as_str().and_then(|s| s.trim().parse().ok())));
    // Whitelisted (non-PII) logging.
    tracing::info!("PayCloud notify: merchant_order_no={merchant_order_no} trans_no={trans_no} trans_status={trans_status:?}");

    // 1) Verify the gateway signature — fail CLOSED (no key / bad sig → reject,
    //    never complete an unverified payment).
    if !st.paycloud.verify(&payload) {
        tracing::warn!("PayCloud notify signature check failed for {merchant_order_no}");
        return Err(AppError::Unauthorized("invalid notify signature".into()));
    }
    if merchant_order_no.is_empty() {
        return Err(AppError::BadRequest("missing merchant_order_no".into()));
    }

    // 2) Load the transaction; only act while it is still pending.
    let txn: Transaction = sqlx::query_as(&format!(
        "SELECT {TXN_COLUMNS} FROM transactions WHERE merchant_order_no = $1"
    ))
    .bind(&merchant_order_no)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("unknown merchant_order_no".into()))?;
    if txn.status == "completed" {
        // Idempotent: already completed — acknowledge without re-writing.
        return Ok("SUCCESS".into());
    }

    // 3) The paid amount must match what we recorded.
    if let Some(paid) = payload
        .get("order_amount")
        .and_then(|v| v.as_f64().or_else(|| v.as_str().and_then(|s| s.parse().ok())))
    {
        let paid_dec = Decimal::from_f64(paid).map(|d| d.round_dp(2)).unwrap_or_default();
        if paid_dec != txn.amount {
            tracing::warn!(
                "PayCloud notify amount mismatch for {merchant_order_no}: {paid_dec} != {}",
                txn.amount
            );
            return Err(AppError::BadRequest("amount mismatch".into()));
        }
    }

    // 4) Map PayCloud's integer status (fail-closed: only 2 completes;
    //    0=paying / 9=created / unknown are not terminal — ack and wait).
    let new_status = match trans_status {
        Some(2) => "completed",
        Some(1) | Some(3) => "failed",
        _ => return Ok("SUCCESS".into()),
    };

    // 5) Move to terminal, but never overwrite an already-completed txn.
    let res = sqlx::query(
        "UPDATE transactions SET status = $1, trans_no = COALESCE(NULLIF($2,''), trans_no) \
         WHERE merchant_order_no = $3 AND status <> 'completed'",
    )
    .bind(new_status)
    .bind(&trans_no)
    .bind(&merchant_order_no)
    .execute(&st.pool)
    .await?;

    // 6) On first completion, record a visible tip in the tips service so it
    //    shows on the creator's public page + feed.
    if new_status == "completed" && res.rows_affected() > 0 {
        record_tip(&st, &txn).await;
    }

    Ok("SUCCESS".into())
}

/// Best-effort: mirror a completed card payment into the tips feed.
async fn record_tip(st: &AppState, txn: &Transaction) {
    let body = json!({
        "creator_id": txn.creator_id,
        "creator_name": txn.creator_name,
        "amount": txn.amount.to_string(),
        "tipper_name": txn.tipper_name,
        "tipper_email": txn.tipper_email,
        "message": txn.message,
        "reference": txn.reference,
        "platform_fee": txn.platform_fee.to_string(),
        "service_fee": txn.service_fee.to_string(),
        "creator_net": txn.creator_net.to_string(),
        "jar_id": txn.jar_id,
    });
    if let Err(e) = st
        .http
        .post(format!("{}/tips/internal/record", st.tips_url))
        .json(&body)
        .send()
        .await
    {
        tracing::warn!("failed to record tip for {}: {e}", txn.reference);
    }
}

async fn order_query(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(merchant_order_no): Path<String>,
) -> Result<Json<Value>, AppError> {
    // Must own the underlying transaction (or be admin).
    let txn: Transaction = sqlx::query_as(&format!(
        "SELECT {TXN_COLUMNS} FROM transactions WHERE merchant_order_no = $1"
    ))
    .bind(&merchant_order_no)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("transaction not found".into()))?;
    require_creator_owner(&st, &headers, txn.creator_id).await?;

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

/// Public: re-sync a pending transaction with the gateway via order.query.
/// Safe unauthenticated — it takes no state from the caller; it only copies
/// PayCloud's own answer (and completes through the same guarded path as the
/// webhook). Used by the payment-callback page while it polls.
async fn reconcile(
    State(st): State<AppState>,
    Path(merchant_order_no): Path<String>,
) -> Result<Json<Value>, AppError> {
    let txn: Transaction = sqlx::query_as(&format!(
        "SELECT {TXN_COLUMNS} FROM transactions WHERE merchant_order_no = $1"
    ))
    .bind(&merchant_order_no)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("transaction not found".into()))?;

    if txn.status != "pending" || !st.paycloud.enabled() {
        return Ok(Json(json!({ "status": txn.status })));
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
    let ts = data.get("trans_status").and_then(|v| {
        v.as_i64()
            .or_else(|| v.as_str().and_then(|s| s.trim().parse().ok()))
    });
    let trans_no = data
        .get("trans_no")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();

    // Same fail-closed completion rule as the webhook: only 2 completes, and
    // only when the gateway's amount matches ours.
    let amount_ok = data
        .get("order_amount")
        .and_then(|v| v.as_f64().or_else(|| v.as_str().and_then(|s| s.parse().ok())))
        .map(|paid| {
            Decimal::from_f64(paid).map(|d| d.round_dp(2)) == Some(txn.amount)
        })
        .unwrap_or(true);

    // 0=paying / 9=created never notify — treat them as expired after an hour
    // so abandoned checkouts stop showing as "processing".
    let expired = chrono::Utc::now() - txn.created_at > chrono::Duration::hours(1);
    let new_status = match ts {
        Some(2) if amount_ok => "completed",
        Some(2) => {
            tracing::warn!("reconcile amount mismatch for {merchant_order_no}");
            "pending"
        }
        Some(1) | Some(3) => "failed",
        Some(0) | Some(9) if expired => "failed",
        _ => "pending",
    };

    if new_status != "pending" {
        let res = sqlx::query(
            "UPDATE transactions SET status = $1, trans_no = COALESCE(NULLIF($2,''), trans_no) \
             WHERE merchant_order_no = $3 AND status <> 'completed'",
        )
        .bind(new_status)
        .bind(&trans_no)
        .bind(&merchant_order_no)
        .execute(&st.pool)
        .await?;
        if new_status == "completed" && res.rows_affected() > 0 {
            record_tip(&st, &txn).await;
        }
        tracing::info!("reconciled {merchant_order_no}: gateway {ts:?} -> {new_status}");
    }

    Ok(Json(json!({ "status": new_status, "gateway_status": ts })))
}

async fn refund(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<RefundReq>,
) -> Result<Json<Value>, AppError> {
    // Refunds move money — admin only.
    let token = bearer(&headers)?;
    let (_uid, role) = verify_token(&st, &token).await?;
    if role != "admin" {
        return Err(AppError::Unauthorized("admin access required to refund".into()));
    }
    if !st.paycloud.enabled() {
        return Err(AppError::Internal("PayCloud not configured".into()));
    }
    let refund_no = format!("rf{}", &Uuid::new_v4().simple().to_string()[..22]);
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
    headers: HeaderMap,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Value>, AppError> {
    require_creator_owner(&st, &headers, creator_id).await?;
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
    headers: HeaderMap,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<Transaction>>, AppError> {
    require_creator_owner(&st, &headers, creator_id).await?;
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
    headers: HeaderMap,
    Json(req): Json<PayoutReq>,
) -> Result<Json<Payout>, AppError> {
    // The creator is the authenticated caller — never trust a body-supplied id.
    let token = bearer(&headers)?;
    let creator_id = my_creator_id(&st, &token)
        .await?
        .ok_or_else(|| AppError::Unauthorized("no creator profile for caller".into()))?;

    let net: (Option<Decimal>,) = sqlx::query_as(
        "SELECT COALESCE(SUM(creator_net),0) FROM transactions WHERE creator_id = $1 AND status = 'completed'",
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
    .bind(creator_id)
    .bind(amount)
    .bind(&reference)
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn creator_payouts(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<Vec<Payout>>, AppError> {
    require_creator_owner(&st, &headers, creator_id).await?;
    let rows: Vec<Payout> = sqlx::query_as(&format!(
        "SELECT {PAYOUT_COLUMNS} FROM payouts WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 200"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

/// Card tips below this lose money to the acquirer's R2 minimum + 2.9%.
fn min_tip() -> f64 {
    env("MIN_TIP_AMOUNT", "10").parse().unwrap_or(10.0)
}

// ── Internal admin endpoints (key-guarded — publicly routable via nginx) ────

/// Latest transactions across every creator.
async fn list_txns_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<Transaction>>, AppError> {
    common::require_internal_key(&headers)?;
    let rows: Vec<Transaction> = sqlx::query_as(&format!(
        "SELECT {TXN_COLUMNS} FROM transactions ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

/// Latest payouts across every creator.
async fn list_payouts_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<Payout>>, AppError> {
    common::require_internal_key(&headers)?;
    let rows: Vec<Payout> = sqlx::query_as(&format!(
        "SELECT {PAYOUT_COLUMNS} FROM payouts ORDER BY created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

#[derive(Deserialize)]
struct PayoutStatusReq {
    status: String,
}

/// Admin settles or fails a payout request.
async fn set_payout_status_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
    Json(req): Json<PayoutStatusReq>,
) -> Result<Json<Payout>, AppError> {
    common::require_internal_key(&headers)?;
    if !matches!(req.status.as_str(), "completed" | "failed" | "pending") {
        return Err(AppError::BadRequest(
            "status must be completed, failed or pending".into(),
        ));
    }
    let row: Option<Payout> = sqlx::query_as(&format!(
        "UPDATE payouts SET status = $1 WHERE id = $2 RETURNING {PAYOUT_COLUMNS}"
    ))
    .bind(&req.status)
    .bind(id)
    .fetch_optional(&st.pool)
    .await?;
    row.map(Json)
        .ok_or_else(|| AppError::NotFound("payout not found".into()))
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
        "creator_name TEXT NOT NULL DEFAULT ''",
        "tipper_name TEXT NOT NULL DEFAULT 'Anonymous'",
        "tipper_email TEXT NOT NULL DEFAULT ''",
        "message TEXT NOT NULL DEFAULT ''",
        "jar_id UUID",
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
    let gateway_public_key = env("PAYCLOUD_GATEWAY_PUBLIC_KEY", "");
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
        gateway_public_key_b64: if gateway_public_key.trim().is_empty() {
            None
        } else {
            Some(gateway_public_key)
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
        http: reqwest::Client::new(),
        accounts_url: env("ACCOUNTS_URL", "http://localhost:8081"),
        creators_url: env("CREATORS_URL", "http://localhost:8082"),
        tips_url: env("TIPS_URL", "http://localhost:8084"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/payments/quote", post(quote))
        .route("/payments/charge", post(charge))
        .route("/payments/checkout", post(checkout))
        .route("/payments/notify", post(notify))
        .route("/payments/refund", post(refund))
        .route("/payments/order/:merchant_order_no", get(order_query))
        .route("/payments/reconcile/:merchant_order_no", post(reconcile))
        .route("/payments/payout", post(request_payout))
        .route("/payments/creator/:creator_id/balance", get(creator_balance))
        .route(
            "/payments/creator/:creator_id/transactions",
            get(creator_transactions),
        )
        .route("/payments/creator/:creator_id/payouts", get(creator_payouts))
        .route("/payments/:reference", get(get_transaction))
        .route("/internal/transactions", get(list_txns_internal))
        .route("/internal/payouts", get(list_payouts_internal))
        .route("/internal/payouts/:id/status", post(set_payout_status_internal))
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
