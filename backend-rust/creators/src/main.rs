//! Creators microservice — owns creator profiles.
//!
//! Creating a profile requires a valid JWT, which this service validates by
//! calling the accounts service (`ACCOUNTS_URL/internal/verify-token`). It also
//! exposes internal lookups that the tips service uses to resolve a creator.

use axum::extract::{Path, State};
use axum::http::{header::AUTHORIZATION, HeaderMap};
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
    accounts_url: String,
    tips_url: String,
    internal_key: String,
}

#[derive(sqlx::FromRow, Serialize)]
struct Creator {
    id: Uuid,
    user_id: Uuid,
    display_name: String,
    slug: String,
    tagline: String,
    category: String,
    tip_goal: Option<Decimal>,
    is_active: bool,
    kyc_status: String,
    avatar_url: String,
    cover_url: String,
    is_featured: bool,
    tip_presets: String,
    thanks_note: String,
    links: String,
    theme: String,
    profile_type: String,       // "individual" | "organisation"
    org_type: String,           // "" | "ngo" | "church" | "school" | "business" | "other"
    registration_number: String,// NPO/company reg for orgs (public but light-weight)
    country: String,            // ISO like "ZA"
    city: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

const CREATOR_COLUMNS: &str =
    "id, user_id, display_name, slug, tagline, category, tip_goal, is_active, kyc_status, avatar_url, cover_url, is_featured, tip_presets, thanks_note, links, theme, profile_type, org_type, registration_number, country, city, created_at";

#[derive(sqlx::FromRow, Serialize)]
struct SupportTier {
    id: Uuid,
    creator_id: Uuid,
    name: String,
    price: Decimal,
    description: String,
    perks: Vec<String>,
    is_active: bool,
    sort_order: i32,
    created_at: chrono::DateTime<chrono::Utc>,
}

const TIER_COLUMNS: &str =
    "id, creator_id, name, price, description, perks, is_active, sort_order, created_at";

#[derive(sqlx::FromRow, Serialize)]
struct Jar {
    id: Uuid,
    creator_id: Uuid,
    name: String,
    slug: String,
    description: String,
    goal: Option<Decimal>,
    is_active: bool,
    created_at: chrono::DateTime<chrono::Utc>,
}

const JAR_COLUMNS: &str = "id, creator_id, name, slug, description, goal, is_active, created_at";

// ── Helpers ─────────────────────────────────────────────────────────────────

fn slugify(input: &str) -> String {
    let mut out = String::new();
    let mut last_dash = false;
    for c in input.trim().chars() {
        if c.is_ascii_alphanumeric() {
            out.push(c.to_ascii_lowercase());
            last_dash = false;
        } else if !last_dash && !out.is_empty() {
            out.push('-');
            last_dash = true;
        }
    }
    while out.ends_with('-') {
        out.pop();
    }
    if out.is_empty() {
        out.push_str("creator");
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
    #[allow(dead_code)]
    email: String,
    #[allow(dead_code)]
    role: String,
}

/// Ask the accounts service to validate the caller's token. This is the
/// creators -> accounts service-to-service hop.
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

// ── Request bodies ──────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct CreateReq {
    display_name: String,
    tagline: Option<String>,
    category: Option<String>,
    tip_goal: Option<f64>,
    slug: Option<String>,
    /// "individual" (default) or "organisation"
    profile_type: Option<String>,
    /// For organisations: "ngo" | "church" | "school" | "business" | "other"
    org_type: Option<String>,
    registration_number: Option<String>,
    country: Option<String>,
    city: Option<String>,
}

// ── Handlers ────────────────────────────────────────────────────────────────

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "creators" }))
}

async fn create_creator(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<CreateReq>,
) -> Result<Json<Creator>, AppError> {
    let token = bearer(&headers)?;
    let user_id = verify_caller(&st, &token).await?;

    let display = req.display_name.trim();
    if display.is_empty() {
        return Err(AppError::BadRequest("display_name is required".into()));
    }
    let slug = req
        .slug
        .filter(|s| !s.trim().is_empty())
        .map(|s| slugify(&s))
        .unwrap_or_else(|| slugify(display));
    let tip_goal = req
        .tip_goal
        .and_then(Decimal::from_f64_retain)
        .map(|d| d.round_dp(2));

    // Normalise profile_type — "organisation" is the only non-default.
    let profile_type = match req.profile_type.as_deref() {
        Some("organisation") | Some("org") | Some("ngo") | Some("church") => "organisation",
        _ => "individual",
    }.to_string();
    let org_type = match req.org_type.as_deref() {
        Some(v @ ("ngo" | "church" | "school" | "business" | "other")) => v.to_string(),
        _ => String::new(),
    };
    let country = req.country.unwrap_or_default().chars().take(4).collect::<String>().to_uppercase();
    let city = req.city.unwrap_or_default().chars().take(80).collect::<String>();
    let registration = req.registration_number.unwrap_or_default().chars().take(60).collect::<String>();

    let row: Creator = sqlx::query_as(&format!(
        "INSERT INTO creator_profiles
            (id, user_id, display_name, slug, tagline, category, tip_goal,
             profile_type, org_type, registration_number, country, city)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
         RETURNING {CREATOR_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(user_id)
    .bind(display)
    .bind(&slug)
    .bind(req.tagline.unwrap_or_default())
    .bind(req.category.unwrap_or_default())
    .bind(tip_goal)
    .bind(profile_type)
    .bind(org_type)
    .bind(registration)
    .bind(country)
    .bind(city)
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("that slug or user already has a profile".into())
        }
        _ => e.into(),
    })?;

    Ok(Json(row))
}

async fn list_creators(State(st): State<AppState>) -> Result<Json<Vec<Creator>>, AppError> {
    let rows: Vec<Creator> = sqlx::query_as(&format!(
        "SELECT {CREATOR_COLUMNS} FROM creator_profiles WHERE is_active = TRUE ORDER BY is_featured DESC, created_at DESC LIMIT 200"
    ))
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn get_by_slug(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<Creator>, AppError> {
    let row: Creator =
        sqlx::query_as(&format!("SELECT {CREATOR_COLUMNS} FROM creator_profiles WHERE slug = $1"))
            .bind(slug)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("creator not found".into()))?;
    Ok(Json(row))
}

/// Internal: resolve a creator by id (used by the tips service).
async fn get_by_id(
    State(st): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Creator>, AppError> {
    let row: Creator =
        sqlx::query_as(&format!("SELECT {CREATOR_COLUMNS} FROM creator_profiles WHERE id = $1"))
            .bind(id)
            .fetch_optional(&st.pool)
            .await?
            .ok_or_else(|| AppError::NotFound("creator not found".into()))?;
    Ok(Json(row))
}

// ── Tiers, jars, my-profile ─────────────────────────────────────────────────

#[derive(Deserialize)]
struct CreateTierReq {
    name: String,
    price: f64,
    description: Option<String>,
    perks: Option<Vec<String>>,
    sort_order: Option<i32>,
}

#[derive(Deserialize)]
struct CreateJarReq {
    name: String,
    description: Option<String>,
    goal: Option<f64>,
}

/// (creator_id, owner_user_id) for a slug, or 404.
async fn creator_ids_by_slug(st: &AppState, slug: &str) -> Result<(Uuid, Uuid), AppError> {
    sqlx::query_as("SELECT id, user_id FROM creator_profiles WHERE slug = $1")
        .bind(slug)
        .fetch_optional(&st.pool)
        .await?
        .ok_or_else(|| AppError::NotFound("creator not found".into()))
}

async fn list_tiers(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<Vec<SupportTier>>, AppError> {
    let (creator_id, _) = creator_ids_by_slug(&st, &slug).await?;
    let rows: Vec<SupportTier> = sqlx::query_as(&format!(
        "SELECT {TIER_COLUMNS} FROM support_tiers WHERE creator_id = $1 AND is_active = TRUE ORDER BY sort_order, price"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn create_tier(
    State(st): State<AppState>,
    Path(slug): Path<String>,
    headers: HeaderMap,
    Json(req): Json<CreateTierReq>,
) -> Result<Json<SupportTier>, AppError> {
    let user_id = verify_caller(&st, &bearer(&headers)?).await?;
    let (creator_id, owner) = creator_ids_by_slug(&st, &slug).await?;
    if owner != user_id {
        return Err(AppError::Unauthorized("not your creator profile".into()));
    }
    if req.name.trim().is_empty() {
        return Err(AppError::BadRequest("name is required".into()));
    }
    let price = Decimal::from_f64_retain(req.price)
        .map(|d| d.round_dp(2))
        .ok_or_else(|| AppError::BadRequest("invalid price".into()))?;
    let perks = req.perks.unwrap_or_default();
    let row: SupportTier = sqlx::query_as(&format!(
        "INSERT INTO support_tiers (id, creator_id, name, price, description, perks, sort_order)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING {TIER_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(creator_id)
    .bind(req.name.trim())
    .bind(price)
    .bind(req.description.unwrap_or_default())
    .bind(&perks)
    .bind(req.sort_order.unwrap_or(0))
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn list_jars(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<Vec<Jar>>, AppError> {
    let (creator_id, _) = creator_ids_by_slug(&st, &slug).await?;
    let rows: Vec<Jar> = sqlx::query_as(&format!(
        "SELECT {JAR_COLUMNS} FROM jars WHERE creator_id = $1 AND is_active = TRUE ORDER BY created_at DESC"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn get_jar(
    State(st): State<AppState>,
    Path((slug, jar_slug)): Path<(String, String)>,
) -> Result<Json<Jar>, AppError> {
    let (creator_id, _) = creator_ids_by_slug(&st, &slug).await?;
    let row: Jar = sqlx::query_as(&format!(
        "SELECT {JAR_COLUMNS} FROM jars WHERE creator_id = $1 AND slug = $2"
    ))
    .bind(creator_id)
    .bind(jar_slug)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("jar not found".into()))?;
    Ok(Json(row))
}

async fn create_jar(
    State(st): State<AppState>,
    Path(slug): Path<String>,
    headers: HeaderMap,
    Json(req): Json<CreateJarReq>,
) -> Result<Json<Jar>, AppError> {
    let user_id = verify_caller(&st, &bearer(&headers)?).await?;
    let (creator_id, owner) = creator_ids_by_slug(&st, &slug).await?;
    if owner != user_id {
        return Err(AppError::Unauthorized("not your creator profile".into()));
    }
    if req.name.trim().is_empty() {
        return Err(AppError::BadRequest("name is required".into()));
    }
    let jar_slug = slugify(&req.name);
    let goal = req
        .goal
        .and_then(Decimal::from_f64_retain)
        .map(|d| d.round_dp(2));
    let row: Jar = sqlx::query_as(&format!(
        "INSERT INTO jars (id, creator_id, name, slug, description, goal)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING {JAR_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(creator_id)
    .bind(req.name.trim())
    .bind(&jar_slug)
    .bind(req.description.unwrap_or_default())
    .bind(goal)
    .fetch_one(&st.pool)
    .await
    .map_err(|e| match &e {
        sqlx::Error::Database(db) if db.code().as_deref() == Some("23505") => {
            AppError::Conflict("a jar with that name already exists".into())
        }
        _ => e.into(),
    })?;
    Ok(Json(row))
}

/// The caller's own creator profile (by user id from the token).
#[derive(Deserialize)]
struct UpdateMeReq {
    display_name: Option<String>,
    tagline: Option<String>,
    category: Option<String>,
    tip_goal: Option<f64>,
    avatar_url: Option<String>,
    cover_url: Option<String>,
    /// JSON array of preset amounts, e.g. [20, 50, 100]
    tip_presets: Option<serde_json::Value>,
    thanks_note: Option<String>,
    /// JSON object {instagram, twitter, youtube, website}
    links: Option<serde_json::Value>,
    /// JSON object {bank, account_name, account_no} — never exposed publicly
    bank_details: Option<serde_json::Value>,
    /// Accent colour for the public page, e.g. "#12A25C"
    theme: Option<String>,
    country: Option<String>,
    city: Option<String>,
    org_type: Option<String>,
    registration_number: Option<String>,
}

/// Creator edits their own profile (partial update; images as data URLs).
async fn update_me(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<UpdateMeReq>,
) -> Result<Json<Creator>, AppError> {
    let token = bearer(&headers)?;
    let user_id = verify_caller(&st, &token).await?;
    if let Some(d) = &req.display_name {
        if d.trim().is_empty() || d.len() > 60 {
            return Err(AppError::BadRequest("display_name must be 1–60 characters".into()));
        }
    }
    for (label, img) in [("avatar", &req.avatar_url), ("cover", &req.cover_url)] {
        if let Some(v) = img {
            if v.len() > 500_000 {
                return Err(AppError::BadRequest(format!("{label} image is too large")));
            }
            if !v.is_empty() && !v.starts_with("data:image/") {
                return Err(AppError::BadRequest(format!("{label} must be an image data URL")));
            }
        }
    }
    let tip_goal = req.tip_goal.and_then(Decimal::from_f64_retain).map(|d| d.round_dp(2));
    let to_json = |v: Option<serde_json::Value>, cap: usize| -> Result<Option<String>, AppError> {
        match v {
            None => Ok(None),
            Some(val) => {
                let s = val.to_string();
                if s.len() > cap {
                    return Err(AppError::BadRequest("field too large".into()));
                }
                Ok(Some(s))
            }
        }
    };
    let presets = to_json(req.tip_presets, 200)?;
    let links = to_json(req.links, 1000)?;
    let bank = to_json(req.bank_details, 1000)?;
    let row: Option<Creator> = sqlx::query_as(&format!(
        "UPDATE creator_profiles SET
            display_name = COALESCE($1, display_name),
            tagline      = COALESCE($2, tagline),
            category     = COALESCE($3, category),
            tip_goal     = COALESCE($4, tip_goal),
            avatar_url   = COALESCE($5, avatar_url),
            cover_url    = COALESCE($6, cover_url),
            tip_presets  = COALESCE($7, tip_presets),
            thanks_note  = COALESCE($8, thanks_note),
            links        = COALESCE($9, links),
            bank_details = COALESCE($10, bank_details),
            theme        = COALESCE($11, theme),
            country      = COALESCE($12, country),
            city         = COALESCE($13, city),
            org_type     = COALESCE($14, org_type),
            registration_number = COALESCE($15, registration_number)
         WHERE user_id = $16 RETURNING {CREATOR_COLUMNS}"
    ))
    .bind(req.display_name.map(|d| d.trim().to_string()))
    .bind(req.tagline)
    .bind(req.category)
    .bind(tip_goal)
    .bind(req.avatar_url)
    .bind(req.cover_url)
    .bind(presets)
    .bind(req.thanks_note.map(|t| t.chars().take(300).collect::<String>()))
    .bind(links)
    .bind(bank)
    .bind(req.theme.filter(|t| t.is_empty() || (t.starts_with('#') && t.len() <= 9)))
    .bind(req.country.map(|c| c.chars().take(4).collect::<String>().to_uppercase()))
    .bind(req.city.map(|c| c.chars().take(80).collect::<String>()))
    .bind(req.org_type.filter(|v| matches!(v.as_str(), "" | "ngo" | "church" | "school" | "business" | "other")))
    .bind(req.registration_number.map(|r| r.chars().take(60).collect::<String>()))
    .bind(user_id)
    .fetch_optional(&st.pool)
    .await?;
    row.map(Json)
        .ok_or_else(|| AppError::NotFound("no creator profile for this user".into()))
}

/// The caller's stored payout bank details (kept off the public profile).
async fn get_my_bank(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<serde_json::Value>, AppError> {
    let token = bearer(&headers)?;
    let user_id = verify_caller(&st, &token).await?;
    let row: Option<(String,)> =
        sqlx::query_as("SELECT bank_details FROM creator_profiles WHERE user_id = $1")
            .bind(user_id)
            .fetch_optional(&st.pool)
            .await?;
    let raw = row.map(|r| r.0).unwrap_or_default();
    let parsed: serde_json::Value = serde_json::from_str(&raw).unwrap_or(json!({}));
    Ok(Json(parsed))
}

async fn get_me(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Creator>, AppError> {
    let user_id = verify_caller(&st, &bearer(&headers)?).await?;
    let row: Creator = sqlx::query_as(&format!(
        "SELECT {CREATOR_COLUMNS} FROM creator_profiles WHERE user_id = $1"
    ))
    .bind(user_id)
    .fetch_optional(&st.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("no creator profile for this user".into()))?;
    Ok(Json(row))
}

// ── Internal admin endpoints (key-guarded — publicly routable via nginx) ────

/// Every profile (active or not), images reduced to booleans to keep the
/// payload light (avatar/cover are data URLs).
async fn list_all_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<serde_json::Value>>, AppError> {
    common::require_internal_key(&headers)?;
    use sqlx::Row as _;
    let rows = sqlx::query(
        "SELECT id, user_id, display_name, slug, tagline, category, tip_goal, is_active, kyc_status,
                avatar_url, cover_url, is_featured, bank_details, profile_type, country, city, org_type, created_at
         FROM creator_profiles ORDER BY created_at DESC LIMIT 300",
    )
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(
        rows.into_iter()
            .map(|r| {
                let avatar_url: String = r.try_get("avatar_url").unwrap_or_default();
                let cover_url: String = r.try_get("cover_url").unwrap_or_default();
                let bank_details: String = r.try_get("bank_details").unwrap_or_default();
                json!({
                    "id": r.try_get::<Uuid, _>("id").ok(),
                    "user_id": r.try_get::<Uuid, _>("user_id").ok(),
                    "display_name": r.try_get::<String, _>("display_name").unwrap_or_default(),
                    "slug": r.try_get::<String, _>("slug").unwrap_or_default(),
                    "tagline": r.try_get::<String, _>("tagline").unwrap_or_default(),
                    "category": r.try_get::<String, _>("category").unwrap_or_default(),
                    "tip_goal": r.try_get::<Option<Decimal>, _>("tip_goal").ok().flatten(),
                    "is_active": r.try_get::<bool, _>("is_active").unwrap_or(false),
                    "kyc_status": r.try_get::<String, _>("kyc_status").unwrap_or_default(),
                    "is_featured": r.try_get::<bool, _>("is_featured").unwrap_or(false),
                    "has_avatar": !avatar_url.is_empty(),
                    "has_cover": !cover_url.is_empty(),
                    "bank_details": serde_json::from_str::<serde_json::Value>(&bank_details).unwrap_or(json!({})),
                    "profile_type": r.try_get::<String, _>("profile_type").unwrap_or_default(),
                    "country": r.try_get::<String, _>("country").unwrap_or_default(),
                    "city": r.try_get::<String, _>("city").unwrap_or_default(),
                    "org_type": r.try_get::<String, _>("org_type").unwrap_or_default(),
                    "created_at": r.try_get::<chrono::DateTime<chrono::Utc>, _>("created_at").ok(),
                })
            })
            .collect(),
    ))
}

#[derive(Deserialize)]
struct SetActiveReq {
    is_active: bool,
}

async fn set_active_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
    Json(req): Json<SetActiveReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    common::require_internal_key(&headers)?;
    let res = sqlx::query("UPDATE creator_profiles SET is_active = $1 WHERE id = $2")
        .bind(req.is_active)
        .bind(id)
        .execute(&st.pool)
        .await?;
    if res.rows_affected() == 0 {
        return Err(AppError::NotFound("creator not found".into()));
    }
    Ok(Json(json!({ "id": id, "is_active": req.is_active })))
}

#[derive(Deserialize)]
struct SetFeaturedReq {
    is_featured: bool,
}

/// Internal (admin portal): pin/unpin a creator on the landing page.
async fn set_featured_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
    Json(req): Json<SetFeaturedReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    common::require_internal_key(&headers)?;
    let res = sqlx::query("UPDATE creator_profiles SET is_featured = $1 WHERE id = $2")
        .bind(req.is_featured)
        .bind(id)
        .execute(&st.pool)
        .await?;
    if res.rows_affected() == 0 {
        return Err(AppError::NotFound("creator not found".into()));
    }
    Ok(Json(json!({ "id": id, "is_featured": req.is_featured })))
}

#[derive(Deserialize)]
struct SetKycReq {
    status: String,
}

/// Internal (admin portal): set a creator's KYC status.
async fn set_kyc_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
    Json(req): Json<SetKycReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    common::require_internal_key(&headers)?;
    if !matches!(
        req.status.as_str(),
        "not_started" | "pending" | "verified" | "rejected"
    ) {
        return Err(AppError::BadRequest("invalid kyc status".into()));
    }
    let res = sqlx::query("UPDATE creator_profiles SET kyc_status = $1 WHERE id = $2")
        .bind(&req.status)
        .bind(id)
        .execute(&st.pool)
        .await?;
    if res.rows_affected() == 0 {
        return Err(AppError::NotFound("creator not found".into()));
    }
    Ok(Json(json!({ "id": id, "kyc_status": req.status })))
}

/// Internal (admin portal): delete a creator profile and everything it owns.
async fn delete_creator_internal(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    common::require_internal_key(&headers)?;
    sqlx::query("DELETE FROM studio_designs WHERE creator_id = $1").bind(id).execute(&st.pool).await?;
    sqlx::query("DELETE FROM support_tiers WHERE creator_id = $1").bind(id).execute(&st.pool).await?;
    sqlx::query("DELETE FROM jars WHERE creator_id = $1").bind(id).execute(&st.pool).await?;
    let res = sqlx::query("DELETE FROM creator_profiles WHERE id = $1")
        .bind(id)
        .execute(&st.pool)
        .await?;
    if res.rows_affected() == 0 {
        return Err(AppError::NotFound("creator not found".into()));
    }
    Ok(Json(json!({ "deleted": id })))
}

/// Owner deletes one of their jars.
async fn delete_jar(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let res = sqlx::query("DELETE FROM jars WHERE id = $1 AND creator_id = $2")
        .bind(id)
        .bind(creator_id)
        .execute(&st.pool)
        .await?;
    if res.rows_affected() == 0 {
        return Err(AppError::NotFound("jar not found".into()));
    }
    Ok(Json(json!({ "deleted": id })))
}

// ── Exclusive posts — supporter-only content, unlocked by tipping this month ─

#[derive(sqlx::FromRow, Serialize)]
struct ExclusivePost {
    id: Uuid,
    creator_id: Uuid,
    title: String,
    body: String,
    image_url: String,
    /// "post" | "video" | "audio" | "gallery"
    kind: String,
    /// External URL for video/audio (YouTube, Vimeo, MP3, etc.)
    media_url: String,
    /// "monthly_tip" | "subscription" | "one_tip" | "public"
    access: String,
    /// Minimum tip amount (rand) required this month for monthly_tip
    min_tip: Decimal,
    /// If access="subscription", which support_tier is required (nullable)
    tier_id: Option<Uuid>,
    created_at: chrono::DateTime<chrono::Utc>,
}

const POST_COLUMNS: &str =
    "id, creator_id, title, body, image_url, kind, media_url, access, min_tip, tier_id, created_at";

#[derive(Deserialize)]
struct CreatePostReq {
    title: String,
    body: Option<String>,
    image_url: Option<String>,
    kind: Option<String>,
    media_url: Option<String>,
    access: Option<String>,
    min_tip: Option<f64>,
    tier_id: Option<Uuid>,
}

async fn create_post(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<CreatePostReq>,
) -> Result<Json<ExclusivePost>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let title = req.title.trim().chars().take(120).collect::<String>();
    if title.is_empty() {
        return Err(AppError::BadRequest("title is required".into()));
    }
    let image = req.image_url.unwrap_or_default();
    if image.len() > 500_000 {
        return Err(AppError::BadRequest("image is too large".into()));
    }
    let kind = match req.kind.as_deref() {
        Some(v @ ("post" | "video" | "audio" | "gallery")) => v.to_string(),
        _ => "post".to_string(),
    };
    let access = match req.access.as_deref() {
        Some(v @ ("monthly_tip" | "subscription" | "one_tip" | "public")) => v.to_string(),
        _ => "monthly_tip".to_string(),
    };
    let media_url = req.media_url.unwrap_or_default().chars().take(1000).collect::<String>();
    let min_tip = req
        .min_tip
        .and_then(|v| Decimal::from_f64_retain(v.max(0.0)))
        .map(|d| d.round_dp(2))
        .unwrap_or_else(|| Decimal::new(10, 0));
    let row: ExclusivePost = sqlx::query_as(&format!(
        "INSERT INTO exclusive_posts
            (id, creator_id, title, body, image_url, kind, media_url, access, min_tip, tier_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING {POST_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(creator_id)
    .bind(title)
    .bind(req.body.unwrap_or_default().chars().take(5000).collect::<String>())
    .bind(image)
    .bind(kind)
    .bind(media_url)
    .bind(access)
    .bind(min_tip)
    .bind(req.tier_id)
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

async fn my_posts(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<ExclusivePost>>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let rows: Vec<ExclusivePost> = sqlx::query_as(&format!(
        "SELECT {POST_COLUMNS} FROM exclusive_posts WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 100"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

#[derive(Deserialize)]
struct UpdatePostReq {
    title: Option<String>,
    body: Option<String>,
    image_url: Option<String>,
    kind: Option<String>,
    media_url: Option<String>,
    access: Option<String>,
    min_tip: Option<f64>,
    tier_id: Option<Uuid>,
}

async fn update_post(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdatePostReq>,
) -> Result<Json<ExclusivePost>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let kind = req.kind.filter(|v| matches!(v.as_str(), "post" | "video" | "audio" | "gallery"));
    let access = req.access.filter(|v| matches!(v.as_str(), "monthly_tip" | "subscription" | "one_tip" | "public"));
    let min_tip = req.min_tip
        .and_then(|v| Decimal::from_f64_retain(v.max(0.0)))
        .map(|d| d.round_dp(2));
    let row: Option<ExclusivePost> = sqlx::query_as(&format!(
        "UPDATE exclusive_posts SET
            title = COALESCE($1, title),
            body = COALESCE($2, body),
            image_url = COALESCE($3, image_url),
            kind = COALESCE($4, kind),
            media_url = COALESCE($5, media_url),
            access = COALESCE($6, access),
            min_tip = COALESCE($7, min_tip),
            tier_id = COALESCE($8, tier_id)
         WHERE id = $9 AND creator_id = $10
         RETURNING {POST_COLUMNS}"
    ))
    .bind(req.title.map(|t| t.chars().take(120).collect::<String>()))
    .bind(req.body.map(|b| b.chars().take(5000).collect::<String>()))
    .bind(req.image_url)
    .bind(kind)
    .bind(req.media_url.map(|m| m.chars().take(1000).collect::<String>()))
    .bind(access)
    .bind(min_tip)
    .bind(req.tier_id)
    .bind(id)
    .bind(creator_id)
    .fetch_optional(&st.pool)
    .await?;
    row.map(Json).ok_or_else(|| AppError::NotFound("post not found".into()))
}

async fn delete_post(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let res = sqlx::query("DELETE FROM exclusive_posts WHERE id = $1 AND creator_id = $2")
        .bind(id)
        .bind(creator_id)
        .execute(&st.pool)
        .await?;
    if res.rows_affected() == 0 {
        return Err(AppError::NotFound("post not found".into()));
    }
    Ok(Json(json!({ "deleted": id })))
}

/// Public: how many exclusive posts a creator has this month (teaser count).
async fn exclusive_count(
    State(st): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<serde_json::Value>, AppError> {
    let row: Option<(i64,)> = sqlx::query_as(
        "SELECT count(*) FROM exclusive_posts p
         JOIN creator_profiles c ON c.id = p.creator_id
         WHERE c.slug = $1",
    )
    .bind(&slug)
    .fetch_optional(&st.pool)
    .await?;
    Ok(Json(json!({ "count": row.map(|r| r.0).unwrap_or(0) })))
}

#[derive(Deserialize)]
struct UnlockReq {
    email: String,
}

/// A fan unlocks the vault with the email they tipped with this month.
/// The tips service is the authority on whether that email tipped.
#[derive(Serialize)]
struct UnlockResp {
    posts: Vec<ExclusivePost>,
    /// The reasons the caller was granted access — helps the UI explain locks.
    grants: UnlockGrants,
}

#[derive(Serialize, Default)]
struct UnlockGrants {
    tipped_this_month: bool,
    /// The set of tier_ids this email is subscribed to.
    tier_ids: Vec<Uuid>,
    /// The tip amount for the current month, capped for privacy.
    month_tip_total: String,
}

async fn exclusive_unlock(
    State(st): State<AppState>,
    Path(slug): Path<String>,
    Json(req): Json<UnlockReq>,
) -> Result<Json<UnlockResp>, AppError> {
    let email = req.email.trim().to_lowercase();
    if !email.contains('@') {
        return Err(AppError::BadRequest("enter the email you tipped with".into()));
    }
    let creator: Option<(Uuid,)> =
        sqlx::query_as("SELECT id FROM creator_profiles WHERE slug = $1")
            .bind(&slug)
            .fetch_optional(&st.pool)
            .await?;
    let creator_id = creator
        .map(|c| c.0)
        .ok_or_else(|| AppError::NotFound("creator not found".into()))?;

    let resp = st
        .http
        .get(format!(
            "{}/internal/tips/tipped-this-month?creator_id={}&email={}",
            st.tips_url,
            creator_id,
            urlencoding_encode(&email)
        ))
        .header("x-internal-key", &st.internal_key)
        .send()
        .await?;
    let ok = resp.status().is_success()
        && resp
            .json::<serde_json::Value>()
            .await
            .ok()
            .and_then(|v| v.get("tipped").and_then(|t| t.as_bool()))
            .unwrap_or(false);
    // Which tiers is this email subscribed to (for this creator)?
    let tier_rows: Vec<(Uuid,)> = sqlx::query_as(
        "SELECT tier_id FROM subscriptions
         WHERE creator_id = $1 AND lower(email) = $2 AND status = 'active'",
    )
    .bind(creator_id)
    .bind(&email)
    .fetch_all(&st.pool)
    .await?;
    let tier_ids: Vec<Uuid> = tier_rows.into_iter().map(|r| r.0).collect();
    if !ok && tier_ids.is_empty() {
        return Err(AppError::Unauthorized(
            "no tip or subscription from that email — tip R10+ or subscribe to unlock".into(),
        ));
    }
    // Filter posts by their access rules. We still return locked ones with
    // media_url/body blanked so the UI can render teasers.
    let all: Vec<ExclusivePost> = sqlx::query_as(&format!(
        "SELECT {POST_COLUMNS} FROM exclusive_posts WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 200"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    let rows: Vec<ExclusivePost> = all
        .into_iter()
        .filter_map(|p| {
            let granted = match p.access.as_str() {
                "public" => true,
                "subscription" => p.tier_id.map(|t| tier_ids.contains(&t)).unwrap_or(false),
                "monthly_tip" | "one_tip" | _ => ok,
            };
            if granted {
                Some(p)
            } else {
                Some(ExclusivePost {
                    body: String::new(),
                    media_url: String::new(),
                    ..p
                })
            }
        })
        .collect();

    Ok(Json(UnlockResp {
        posts: rows,
        grants: UnlockGrants {
            tipped_this_month: ok,
            tier_ids,
            month_tip_total: String::new(),
        },
    }))
}

/// Creator: list your own tiers (for the composer's tier picker).
async fn my_tiers(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<SupportTier>>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let rows: Vec<SupportTier> = sqlx::query_as(&format!(
        "SELECT {TIER_COLUMNS} FROM support_tiers WHERE creator_id = $1 AND is_active = TRUE ORDER BY sort_order, price"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

#[derive(Serialize)]
struct SubscriberRow {
    id: Uuid,
    tier_id: Uuid,
    tier_name: String,
    email: String,
    name: String,
    status: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

/// Creator: list their subscribers.
async fn my_subscribers(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<SubscriberRow>>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let rows = sqlx::query(
        "SELECT s.id, s.tier_id, COALESCE(t.name, '') AS tier_name, s.email, s.name, s.status, s.created_at
         FROM subscriptions s
         LEFT JOIN support_tiers t ON t.id = s.tier_id
         WHERE s.creator_id = $1 ORDER BY s.created_at DESC LIMIT 500",
    )
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    use sqlx::Row as _;
    Ok(Json(
        rows.into_iter()
            .map(|r| SubscriberRow {
                id: r.try_get("id").unwrap_or_default(),
                tier_id: r.try_get("tier_id").unwrap_or_default(),
                tier_name: r.try_get("tier_name").unwrap_or_default(),
                email: r.try_get("email").unwrap_or_default(),
                name: r.try_get("name").unwrap_or_default(),
                status: r.try_get("status").unwrap_or_default(),
                created_at: r.try_get("created_at").unwrap_or_else(|_| chrono::Utc::now()),
            })
            .collect(),
    ))
}

#[derive(Deserialize)]
struct SubscribeReq {
    tier_id: Uuid,
    email: String,
    name: Option<String>,
}

/// Public: a fan subscribes to a tier. First iteration is trial-friendly —
/// no payment gate here; the tips flow already handles money, this table just
/// records who has access. Idempotent per (creator, tier, email).
async fn subscribe(
    State(st): State<AppState>,
    Path(slug): Path<String>,
    Json(req): Json<SubscribeReq>,
) -> Result<Json<serde_json::Value>, AppError> {
    let email = req.email.trim().to_lowercase();
    if !email.contains('@') {
        return Err(AppError::BadRequest("enter a valid email".into()));
    }
    let creator: Option<(Uuid,)> = sqlx::query_as("SELECT id FROM creator_profiles WHERE slug = $1")
        .bind(&slug)
        .fetch_optional(&st.pool)
        .await?;
    let creator_id = creator
        .map(|c| c.0)
        .ok_or_else(|| AppError::NotFound("creator not found".into()))?;
    // Validate the tier belongs to this creator + is active.
    let tier: Option<(Uuid,)> = sqlx::query_as(
        "SELECT id FROM support_tiers WHERE id = $1 AND creator_id = $2 AND is_active = TRUE",
    )
    .bind(req.tier_id)
    .bind(creator_id)
    .fetch_optional(&st.pool)
    .await?;
    if tier.is_none() {
        return Err(AppError::NotFound("tier not found".into()));
    }
    let name = req.name.unwrap_or_default().chars().take(120).collect::<String>();
    let res = sqlx::query(
        "INSERT INTO subscriptions (id, creator_id, tier_id, email, name)
         VALUES ($1,$2,$3,$4,$5)
         ON CONFLICT (creator_id, tier_id, email) DO UPDATE SET status='active', name = EXCLUDED.name",
    )
    .bind(Uuid::new_v4())
    .bind(creator_id)
    .bind(req.tier_id)
    .bind(&email)
    .bind(name)
    .execute(&st.pool)
    .await?;
    Ok(Json(serde_json::json!({ "subscribed": true, "rows": res.rows_affected() })))
}

/// Minimal percent-encoding for a query value (emails: @ + . are the cases).
fn urlencoding_encode(s: &str) -> String {
    s.chars()
        .map(|c| match c {
            'a'..='z' | 'A'..='Z' | '0'..='9' | '.' | '-' | '_' => c.to_string(),
            other => format!("%{:02X}", other as u32),
        })
        .collect()
}

// ── Studio designs — the creator's saved promo graphics ─────────────────────

#[derive(sqlx::FromRow, Serialize)]
struct StudioDesign {
    id: Uuid,
    creator_id: Uuid,
    title: String,
    kind: String,
    canvas: String,
    thumb: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Deserialize)]
struct SaveDesignReq {
    title: Option<String>,
    kind: Option<String>,
    /// JSON blob of the editor's element state (opaque to the server).
    canvas: String,
    /// Small PNG data-URL preview.
    thumb: Option<String>,
}

/// Resolve the caller's creator id from their bearer token.
async fn my_creator_id(st: &AppState, headers: &HeaderMap) -> Result<Uuid, AppError> {
    let user_id = verify_caller(st, &bearer(headers)?).await?;
    let row: Option<(Uuid,)> =
        sqlx::query_as("SELECT id FROM creator_profiles WHERE user_id = $1")
            .bind(user_id)
            .fetch_optional(&st.pool)
            .await?;
    row.map(|r| r.0)
        .ok_or_else(|| AppError::NotFound("no creator profile for this user".into()))
}

async fn list_designs(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<StudioDesign>>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let rows: Vec<StudioDesign> = sqlx::query_as(
        "SELECT id, creator_id, title, kind, canvas, thumb, created_at
         FROM studio_designs WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 60",
    )
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
}

async fn save_design(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<SaveDesignReq>,
) -> Result<Json<StudioDesign>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let (title, kind, canvas, thumb) = validate_design(req)?;
    let row: StudioDesign = sqlx::query_as(
        "INSERT INTO studio_designs (id, creator_id, title, kind, canvas, thumb)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, creator_id, title, kind, canvas, thumb, created_at",
    )
    .bind(Uuid::new_v4())
    .bind(creator_id)
    .bind(title)
    .bind(kind)
    .bind(canvas)
    .bind(thumb)
    .fetch_one(&st.pool)
    .await?;
    Ok(Json(row))
}

/// Shared request validation. The canvas cap is generous because designs may
/// embed compressed images as data URLs.
fn validate_design(req: SaveDesignReq) -> Result<(String, String, String, String), AppError> {
    if req.canvas.len() > 2_000_000 {
        return Err(AppError::BadRequest("design is too large".into()));
    }
    let thumb = req.thumb.unwrap_or_default();
    if thumb.len() > 500_000 {
        return Err(AppError::BadRequest("thumbnail is too large".into()));
    }
    let kind = match req.kind.as_deref() {
        Some(k @ ("square" | "portrait" | "story" | "landscape")) => k.to_string(),
        _ => "square".to_string(),
    };
    let title = req.title.unwrap_or_default().chars().take(80).collect::<String>();
    Ok((title, kind, req.canvas, thumb))
}

async fn update_design(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
    Json(req): Json<SaveDesignReq>,
) -> Result<Json<StudioDesign>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let (title, kind, canvas, thumb) = validate_design(req)?;
    let row: Option<StudioDesign> = sqlx::query_as(
        "UPDATE studio_designs SET title = $1, kind = $2, canvas = $3, thumb = $4
         WHERE id = $5 AND creator_id = $6
         RETURNING id, creator_id, title, kind, canvas, thumb, created_at",
    )
    .bind(title)
    .bind(kind)
    .bind(canvas)
    .bind(thumb)
    .bind(id)
    .bind(creator_id)
    .fetch_optional(&st.pool)
    .await?;
    row.map(Json)
        .ok_or_else(|| AppError::NotFound("design not found".into()))
}

async fn delete_design(
    State(st): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    let creator_id = my_creator_id(&st, &headers).await?;
    let res = sqlx::query("DELETE FROM studio_designs WHERE id = $1 AND creator_id = $2")
        .bind(id)
        .bind(creator_id)
        .execute(&st.pool)
        .await?;
    if res.rows_affected() == 0 {
        return Err(AppError::NotFound("design not found".into()));
    }
    Ok(Json(json!({ "deleted": id })))
}

// ── Bootstrap ───────────────────────────────────────────────────────────────

async fn init_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS creator_profiles (
            id           UUID PRIMARY KEY,
            user_id      UUID UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            slug         TEXT UNIQUE NOT NULL,
            tagline      TEXT NOT NULL DEFAULT '',
            category     TEXT NOT NULL DEFAULT '',
            tip_goal     NUMERIC(10,2),
            is_active    BOOLEAN NOT NULL DEFAULT TRUE,
            kyc_status   TEXT NOT NULL DEFAULT 'not_started',
            avatar_url   TEXT NOT NULL DEFAULT '',
            cover_url    TEXT NOT NULL DEFAULT '',
            created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    // Existing databases predate the image columns.
    sqlx::query("ALTER TABLE creator_profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT NOT NULL DEFAULT ''")
        .execute(pool)
        .await?;
    sqlx::query("ALTER TABLE creator_profiles ADD COLUMN IF NOT EXISTS cover_url TEXT NOT NULL DEFAULT ''")
        .execute(pool)
        .await?;
    sqlx::query("ALTER TABLE creator_profiles ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT FALSE")
        .execute(pool)
        .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS exclusive_posts (
            id         UUID PRIMARY KEY,
            creator_id UUID NOT NULL,
            title      TEXT NOT NULL,
            body       TEXT NOT NULL DEFAULT '',
            image_url  TEXT NOT NULL DEFAULT '',
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    // Media / access controls — migrate existing rows in place.
    for stmt in [
        "ALTER TABLE exclusive_posts ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'post'",
        "ALTER TABLE exclusive_posts ADD COLUMN IF NOT EXISTS media_url TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE exclusive_posts ADD COLUMN IF NOT EXISTS access TEXT NOT NULL DEFAULT 'monthly_tip'",
        "ALTER TABLE exclusive_posts ADD COLUMN IF NOT EXISTS min_tip NUMERIC(10,2) NOT NULL DEFAULT 10",
        "ALTER TABLE exclusive_posts ADD COLUMN IF NOT EXISTS tier_id UUID",
    ] {
        sqlx::query(stmt).execute(pool).await?;
    }
    // Subscribers — a fan chooses to follow a support tier.
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS subscriptions (
            id          UUID PRIMARY KEY,
            creator_id  UUID NOT NULL,
            tier_id     UUID NOT NULL,
            email       TEXT NOT NULL,
            name        TEXT NOT NULL DEFAULT '',
            status      TEXT NOT NULL DEFAULT 'active',
            period_end  TIMESTAMPTZ,
            created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
            UNIQUE (creator_id, tier_id, email)
        )",
    )
    .execute(pool)
    .await?;
    for col in [
        "tip_presets", "thanks_note", "links", "bank_details", "theme",
        "profile_type", "org_type", "registration_number", "country", "city",
    ] {
        sqlx::query(&format!(
            "ALTER TABLE creator_profiles ADD COLUMN IF NOT EXISTS {col} TEXT NOT NULL DEFAULT ''"
        ))
        .execute(pool)
        .await?;
    }
    // profile_type defaults to 'individual' for existing rows so the public page
    // treats them the same as before.
    sqlx::query("UPDATE creator_profiles SET profile_type='individual' WHERE profile_type=''")
        .execute(pool)
        .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS support_tiers (
            id          UUID PRIMARY KEY,
            creator_id  UUID NOT NULL,
            name        TEXT NOT NULL,
            price       NUMERIC(10,2) NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            perks       TEXT[] NOT NULL DEFAULT '{}',
            is_active   BOOLEAN NOT NULL DEFAULT TRUE,
            sort_order  INT NOT NULL DEFAULT 0,
            created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS jars (
            id          UUID PRIMARY KEY,
            creator_id  UUID NOT NULL,
            name        TEXT NOT NULL,
            slug        TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            goal        NUMERIC(10,2),
            is_active   BOOLEAN NOT NULL DEFAULT TRUE,
            created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
            UNIQUE (creator_id, slug)
        )",
    )
    .execute(pool)
    .await?;
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS studio_designs (
            id         UUID PRIMARY KEY,
            creator_id UUID NOT NULL,
            title      TEXT NOT NULL DEFAULT '',
            kind       TEXT NOT NULL DEFAULT 'square',
            canvas     TEXT NOT NULL,
            thumb      TEXT NOT NULL DEFAULT '',
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

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let db_url = env(
        "DATABASE_URL",
        "postgres://postgres:postgres@localhost:5432/creators_db",
    );
    let pool = connect_with_retry(&db_url).await;
    init_db(&pool).await.expect("failed to initialise schema");

    let state = AppState {
        pool,
        http: reqwest::Client::new(),
        accounts_url: env("ACCOUNTS_URL", "http://localhost:8081"),
        tips_url: env("TIPS_URL", "http://localhost:8084"),
        internal_key: env("INTERNAL_KEY", "tj-internal-dev-key"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/creators", post(create_creator).get(list_creators))
        .route("/creators/me", get(get_me).put(update_me))
        .route("/creators/me/bank", get(get_my_bank))
        .route("/creators/me/posts", get(my_posts).post(create_post))
        .route("/creators/me/posts/:id", axum::routing::put(update_post).delete(delete_post))
        .route("/creators/me/tiers", get(my_tiers))
        .route("/creators/me/subscribers", get(my_subscribers))
        .route("/creators/:slug/subscribe", post(subscribe))
        .route("/creators/me/jars/:id", axum::routing::delete(delete_jar))
        .route("/creators/:slug/exclusive/count", get(exclusive_count))
        .route("/creators/:slug/exclusive/unlock", post(exclusive_unlock))
        .route("/creators/studio/designs", get(list_designs).post(save_design))
        .route(
            "/creators/studio/designs/:id",
            axum::routing::put(update_design).delete(delete_design),
        )
        .route("/creators/:slug", get(get_by_slug))
        .route("/creators/:slug/tiers", get(list_tiers).post(create_tier))
        .route("/creators/:slug/jars", get(list_jars).post(create_jar))
        .route("/creators/:slug/jars/:jar_slug", get(get_jar))
        .route("/internal/creators/all", get(list_all_internal))
        .route(
            "/internal/creators/:id",
            get(get_by_id).delete(delete_creator_internal),
        )
        .route("/internal/creators/:id/active", post(set_active_internal))
        .route("/internal/creators/:id/kyc", post(set_kyc_internal))
        .route("/internal/creators/:id/featured", post(set_featured_internal))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(state);

    let port = env("PORT", "8082");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("creators service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}
