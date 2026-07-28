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
    created_at: chrono::DateTime<chrono::Utc>,
}

const CREATOR_COLUMNS: &str =
    "id, user_id, display_name, slug, tagline, category, tip_goal, is_active, kyc_status, avatar_url, cover_url, is_featured, tip_presets, thanks_note, links, theme, created_at";

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

    let row: Creator = sqlx::query_as(&format!(
        "INSERT INTO creator_profiles (id, user_id, display_name, slug, tagline, category, tip_goal)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING {CREATOR_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(user_id)
    .bind(display)
    .bind(&slug)
    .bind(req.tagline.unwrap_or_default())
    .bind(req.category.unwrap_or_default())
    .bind(tip_goal)
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
            theme        = COALESCE($11, theme)
         WHERE user_id = $12 RETURNING {CREATOR_COLUMNS}"
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
    let rows: Vec<(Uuid, Uuid, String, String, String, String, Option<Decimal>, bool, String, String, String, bool, String, chrono::DateTime<chrono::Utc>)> = sqlx::query_as(
        "SELECT id, user_id, display_name, slug, tagline, category, tip_goal, is_active, kyc_status, avatar_url, cover_url, is_featured, bank_details, created_at
         FROM creator_profiles ORDER BY created_at DESC LIMIT 300",
    )
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(
        rows.into_iter()
            .map(|(id, user_id, display_name, slug, tagline, category, tip_goal, is_active, kyc_status, avatar_url, cover_url, is_featured, bank_details, created_at)| {
                json!({
                    "id": id, "user_id": user_id, "display_name": display_name,
                    "slug": slug, "tagline": tagline, "category": category,
                    "tip_goal": tip_goal, "is_active": is_active,
                    "kyc_status": kyc_status, "is_featured": is_featured, "has_avatar": !avatar_url.is_empty(),
                    "has_cover": !cover_url.is_empty(),
                    "bank_details": serde_json::from_str::<serde_json::Value>(&bank_details).unwrap_or(json!({})),
                    "created_at": created_at,
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
    created_at: chrono::DateTime<chrono::Utc>,
}

const POST_COLUMNS: &str = "id, creator_id, title, body, image_url, created_at";

#[derive(Deserialize)]
struct CreatePostReq {
    title: String,
    body: Option<String>,
    image_url: Option<String>,
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
    let row: ExclusivePost = sqlx::query_as(&format!(
        "INSERT INTO exclusive_posts (id, creator_id, title, body, image_url)
         VALUES ($1, $2, $3, $4, $5) RETURNING {POST_COLUMNS}"
    ))
    .bind(Uuid::new_v4())
    .bind(creator_id)
    .bind(title)
    .bind(req.body.unwrap_or_default().chars().take(5000).collect::<String>())
    .bind(image)
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
async fn exclusive_unlock(
    State(st): State<AppState>,
    Path(slug): Path<String>,
    Json(req): Json<UnlockReq>,
) -> Result<Json<Vec<ExclusivePost>>, AppError> {
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
    if !ok {
        return Err(AppError::Unauthorized(
            "no tip from that email this month — tip R10+ to unlock".into(),
        ));
    }
    let rows: Vec<ExclusivePost> = sqlx::query_as(&format!(
        "SELECT {POST_COLUMNS} FROM exclusive_posts WHERE creator_id = $1 ORDER BY created_at DESC LIMIT 100"
    ))
    .bind(creator_id)
    .fetch_all(&st.pool)
    .await?;
    Ok(Json(rows))
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
    for col in ["tip_presets", "thanks_note", "links", "bank_details", "theme"] {
        sqlx::query(&format!(
            "ALTER TABLE creator_profiles ADD COLUMN IF NOT EXISTS {col} TEXT NOT NULL DEFAULT ''"
        ))
        .execute(pool)
        .await?;
    }
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
        .route("/creators/me/posts/:id", axum::routing::delete(delete_post))
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
