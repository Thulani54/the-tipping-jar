//! Scheduler service — the Rust home for Tipping Jar's cron jobs.
//!
//! Runs as a long-lived service inside the compose stack (no host crontab). It
//! self-schedules with tokio-cron-scheduler and, at 00:00 SAST (22:00 UTC),
//! runs the daily-tips report: for the just-ended SAST day it finds every
//! creator who received completed tips, renders a branded PDF of that day's
//! transactions, and writes it to REPORTS_DIR. Email delivery is gated behind
//! REPORT_EMAIL_ENABLED (off until an SMTP path is chosen).
//!
//! Also serves /health and POST /internal/run-daily-report?date=YYYY-MM-DD for
//! manual runs.

use axum::{
    extract::{Query, State},
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Duration, NaiveDate, TimeZone, Utc};
use chrono_tz::Africa::Johannesburg;
use common::{env, AppError};
use lettre::message::{header::ContentType, Attachment, Message, MultiPart, SinglePart};
use lettre::transport::smtp::authentication::Credentials;
use lettre::{SmtpTransport, Transport};
use printpdf::{
    BuiltinFont, Color, IndirectFontRef, Line, Mm, PdfDocument, PdfLayerReference, Point, Polygon,
    PolygonMode, Rgb, WindingOrder,
};
use rust_decimal::prelude::{FromPrimitive, ToPrimitive};
use rust_decimal::Decimal;
use serde::Deserialize;
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use sqlx::{PgPool, Row};
use std::collections::HashMap;
use std::fs::{create_dir_all, File};
use std::io::BufWriter;
use tokio_cron_scheduler::{Job, JobScheduler};
use uuid::Uuid;

#[derive(Clone)]
struct Pools {
    tips: PgPool,
    creators: PgPool,
    accounts: PgPool,
}

struct TipRow {
    creator_name: String,
    tipper: String,
    amount: Decimal,
    net: Decimal,
    message: Option<String>,
    time: String,
}

struct Summary {
    date: String,
    creators: usize,
    rendered: usize,
    emailed: usize,
    gross: String,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    // Offline PDF preview: `scheduler --selftest` renders a sample and exits.
    if std::env::args().any(|a| a == "--selftest") {
        let d = |v: f64| Decimal::from_f64(v).unwrap_or_default();
        let tips = vec![
            TipRow { creator_name: "Demo".into(), tipper: "Sam".into(), amount: d(80.0), net: d(75.2), message: Some("Love your work! Keep it coming 🙌".into()), time: "09:14".into() },
            TipRow { creator_name: "Demo".into(), tipper: "Thandi M.".into(), amount: d(120.0), net: d(112.8), message: Some("For the Friday mix".into()), time: "13:47".into() },
            TipRow { creator_name: "Demo".into(), tipper: "Anonymous".into(), amount: d(50.0), net: d(47.0), message: None, time: "18:02".into() },
            TipRow { creator_name: "Demo".into(), tipper: "Lerato".into(), amount: d(250.0), net: d(235.0), message: Some("You earned it".into()), time: "21:30".into() },
        ];
        let gross: Decimal = tips.iter().map(|t| t.amount).sum();
        let net: Decimal = tips.iter().map(|t| t.net).sum();
        build_pdf("Demo Creator", "Mon 20 Jul 2026", &tips, gross, net, "/tmp/tj-selftest.pdf").unwrap();
        println!("wrote /tmp/tj-selftest.pdf");
        return;
    }

    let base = env("DB_BASE_URL", "postgres://postgres:postgres@db:5432");
    let pools = Pools {
        tips: connect(&env("TIPS_DATABASE_URL", &format!("{base}/tips_db"))).await,
        creators: connect(&env("CREATORS_DATABASE_URL", &format!("{base}/creators_db"))).await,
        accounts: connect(&env("ACCOUNTS_DATABASE_URL", &format!("{base}/accounts_db"))).await,
    };
    tracing::info!("scheduler connected to tips/creators/accounts databases");

    // Once-only ledger for signup-completion reminders.
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS signup_reminders (
            user_id UUID PRIMARY KEY,
            email TEXT NOT NULL,
            sent_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )",
    )
    .execute(&pools.accounts)
    .await
    .expect("failed to ensure signup_reminders table");

    // Schedule the nightly report. Cron is 6-field (sec min hour dom mon dow),
    // evaluated in UTC — 22:00 UTC = 00:00 SAST.
    let cron = env("DAILY_REPORT_CRON", "0 0 22 * * *");
    let sched = JobScheduler::new().await.expect("scheduler init failed");
    let job_pools = pools.clone();
    let job = Job::new_async(cron.as_str(), move |_uuid, _lock| {
        let pools = job_pools.clone();
        Box::pin(async move {
            tracing::info!("cron fired: daily report");
            match run_daily_report(&pools, None, None).await {
                Ok(s) => tracing::info!(
                    "daily report complete: {} creator(s), {} pdf(s), {} emailed, {}",
                    s.creators,
                    s.rendered,
                    s.emailed,
                    s.gross
                ),
                Err(e) => tracing::error!("daily report failed: {e}"),
            }
        })
    })
    .expect("invalid DAILY_REPORT_CRON");
    sched.add(job).await.expect("failed to add job");

    // Signup-completion reminders: every 30 min, nudge creator accounts that
    // are >12h old and still have no creator page. One email per user, ever.
    let rem_cron = env("SIGNUP_REMINDER_CRON", "0 */30 * * * *");
    let rem_pools = pools.clone();
    let rem_job = Job::new_async(rem_cron.as_str(), move |_uuid, _lock| {
        let pools = rem_pools.clone();
        Box::pin(async move {
            match run_signup_reminders(&pools).await {
                Ok((candidates, sent)) => {
                    if candidates > 0 {
                        tracing::info!("signup reminders: {sent}/{candidates} sent");
                    }
                }
                Err(e) => tracing::error!("signup reminders failed: {e}"),
            }
        })
    })
    .expect("invalid SIGNUP_REMINDER_CRON");
    sched.add(rem_job).await.expect("failed to add reminder job");

    sched.start().await.expect("failed to start scheduler");
    tracing::info!("scheduler started — daily report '{cron}', signup reminders '{rem_cron}' (UTC)");

    let app = Router::new()
        .route("/health", get(health))
        .route("/internal/run-daily-report", post(trigger))
        .route("/internal/run-signup-reminders", post(trigger_reminders))
        .layer(tower_http::cors::CorsLayer::permissive())
        .with_state(pools);

    let port = env("PORT", "8092");
    let addr = format!("0.0.0.0:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");
    tracing::info!("scheduler service listening on {addr}");
    axum::serve(listener, app).await.expect("server error");
}

async fn connect(url: &str) -> PgPool {
    loop {
        match PgPoolOptions::new().max_connections(2).connect(url).await {
            Ok(p) => return p,
            Err(e) => {
                tracing::warn!("waiting for database ({url}): {e}");
                tokio::time::sleep(std::time::Duration::from_secs(2)).await;
            }
        }
    }
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({ "status": "ok", "service": "scheduler" }))
}

#[derive(Deserialize)]
struct RunParams {
    date: Option<String>,
    /// Force every report to one recipient (testing) — `?to=you@example.com`.
    to: Option<String>,
}

/// Manual trigger — runs the report now for `?date=YYYY-MM-DD` (defaults to the
/// previous SAST day, same as the nightly run).
async fn trigger(
    State(pools): State<Pools>,
    Query(q): Query<RunParams>,
) -> Result<Json<serde_json::Value>, AppError> {
    let date = match q.date.as_deref() {
        Some(d) => Some(
            NaiveDate::parse_from_str(d, "%Y-%m-%d")
                .map_err(|_| AppError::BadRequest("date must be YYYY-MM-DD".into()))?,
        ),
        None => None,
    };
    let s = run_daily_report(&pools, date, q.to).await?;
    Ok(Json(json!({
        "date": s.date,
        "creators": s.creators,
        "rendered": s.rendered,
        "emailed": s.emailed,
        "gross": s.gross,
        "email": if env("REPORT_EMAIL_ENABLED", "0") == "1" { "enabled" } else { "disabled" },
    })))
}

/// Manual trigger for the signup-completion reminders.
async fn trigger_reminders(
    State(pools): State<Pools>,
) -> Result<Json<serde_json::Value>, AppError> {
    let (candidates, sent) = run_signup_reminders(&pools).await?;
    let o = env("COMMS_OVERRIDE_TO", "");
    let override_val = if o.is_empty() { serde_json::Value::Null } else { json!(o) };
    Ok(Json(json!({
        "candidates": candidates,
        "sent": sent,
        "override": override_val,
    })))
}

/// Find creator accounts older than REMINDER_AFTER_HOURS with no creator page
/// and no prior reminder, then email the user a nudge and alert the admins.
/// COMMS_OVERRIDE_TO reroutes every email (user + admin) while testing.
async fn run_signup_reminders(pools: &Pools) -> Result<(usize, usize), AppError> {
    let after_hours: i64 = env("REMINDER_AFTER_HOURS", "12").parse().unwrap_or(12);
    let window_days: i64 = env("REMINDER_WINDOW_DAYS", "14").parse().unwrap_or(14);

    let rows = sqlx::query(
        "SELECT u.id, u.email, u.username, u.created_at
         FROM users u
         WHERE u.role = 'creator'
           AND u.created_at < now() - ($1 || ' hours')::interval
           AND u.created_at > now() - ($2 || ' days')::interval
           AND NOT EXISTS (SELECT 1 FROM signup_reminders r WHERE r.user_id = u.id)
         ORDER BY u.created_at",
    )
    .bind(after_hours.to_string())
    .bind(window_days.to_string())
    .fetch_all(&pools.accounts)
    .await?;

    if rows.is_empty() {
        return Ok((0, 0));
    }

    // Drop anyone who does have a creator page.
    let ids: Vec<Uuid> = rows.iter().filter_map(|r| r.try_get("id").ok()).collect();
    let with_profile: Vec<Uuid> =
        sqlx::query("SELECT user_id FROM creator_profiles WHERE user_id = ANY($1)")
            .bind(&ids)
            .fetch_all(&pools.creators)
            .await?
            .iter()
            .filter_map(|r| r.try_get("user_id").ok())
            .collect();

    let override_to = env("COMMS_OVERRIDE_TO", "");
    let admins: Vec<String> = env("ADMIN_EMAILS", "")
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    let mut candidates = 0usize;
    let mut sent = 0usize;
    for r in &rows {
        let uid: Uuid = r.try_get("id")?;
        if with_profile.contains(&uid) {
            continue;
        }
        candidates += 1;
        let email: String = r.try_get("email").unwrap_or_default();
        let username: String = r.try_get("username").unwrap_or_else(|_| "there".into());
        let created: DateTime<Utc> = r.try_get("created_at").unwrap_or_else(|_| Utc::now());
        let signed_up = created
            .with_timezone(&Johannesburg)
            .format("%a %d %b %Y, %H:%M")
            .to_string();

        let user_to = if override_to.is_empty() { email.clone() } else { override_to.clone() };
        let (subj, text, html) = reminder_email(&username);
        let send = {
            let user_to = user_to.clone();
            tokio::task::spawn_blocking(move || send_html_email(&user_to, &subj, &text, &html))
                .await
                .unwrap_or_else(|e| Err(format!("join error: {e}")))
        };
        match send {
            Ok(()) => {
                sent += 1;
                tracing::info!("signup reminder for {email} sent to {user_to}");
                sqlx::query("INSERT INTO signup_reminders (user_id, email) VALUES ($1, $2) ON CONFLICT DO NOTHING")
                    .bind(uid)
                    .bind(&email)
                    .execute(&pools.accounts)
                    .await?;
            }
            Err(e) => {
                tracing::error!("signup reminder for {email} failed: {e}");
                continue; // no admin alert, and retry next cycle
            }
        }

        // Admin alert (one per admin; all rerouted while COMMS_OVERRIDE_TO is set).
        let admin_targets: Vec<String> = if override_to.is_empty() {
            admins.clone()
        } else {
            vec![override_to.clone()]
        };
        for admin in admin_targets {
            let (subj, text, html) = admin_alert_email(&email, &username, &signed_up, after_hours);
            let res = tokio::task::spawn_blocking(move || send_html_email(&admin, &subj, &text, &html))
                .await
                .unwrap_or_else(|e| Err(format!("join error: {e}")));
            if let Err(e) = res {
                tracing::error!("admin alert for {email} failed: {e}");
            }
        }
    }

    Ok((candidates, sent))
}

fn reminder_email(username: &str) -> (String, String, String) {
    let subject = "Your Tipping Jar is almost ready — finish setting up".to_string();
    let text = format!(
        "Hi {username}, you signed up for Tipping Jar but haven't created your creator page yet. \
         It takes about two minutes: https://www.tippingjar.co.za/dashboard"
    );
    let html = format!(
        r#"<div style="font-family:Arial,Helvetica,sans-serif;background:#eff2f0;padding:24px">
  <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;border:1px solid #e2e7e3">
    <div style="background:#0f2439;padding:24px 28px;color:#fff">
      <div style="font-size:20px;font-weight:800">Tipping Jar</div>
      <div style="opacity:.8;font-size:14px;margin-top:2px">Your jar is waiting</div>
    </div>
    <div style="padding:24px 28px;color:#0f2439">
      <p style="margin:0 0 6px;font-size:16px">Hi {username},</p>
      <p style="margin:0 0 14px;color:#5a6b7b">You created your account but haven't set up your creator page yet —
      that's the link fans use to tip you. It takes about two minutes:</p>
      <ol style="margin:0 0 18px;padding-left:20px;color:#5a6b7b">
        <li>Pick your display name and handle</li>
        <li>Add a one-line tagline</li>
        <li>Share your link — start receiving tips</li>
      </ol>
      <a href="https://www.tippingjar.co.za/dashboard" style="display:inline-block;background:#0f2439;color:#fff;text-decoration:none;padding:12px 22px;border-radius:999px;font-weight:600">Finish my page</a>
    </div>
    <div style="padding:16px 28px;color:#8a97a4;font-size:12px;border-top:1px solid #e2e7e3">
      One-time reminder because your Tipping Jar signup is incomplete. If this wasn't you, ignore this email.
    </div>
  </div>
</div>"#
    );
    (subject, text, html)
}

fn admin_alert_email(
    email: &str,
    username: &str,
    signed_up: &str,
    after_hours: i64,
) -> (String, String, String) {
    let subject = format!("[Tipping Jar] Incomplete signup: {email}");
    let text = format!(
        "User {username} <{email}> signed up on {signed_up} (SAST) and still has no creator page after {after_hours}h. A one-time reminder was just emailed to them."
    );
    let html = format!(
        r#"<div style="font-family:Arial,Helvetica,sans-serif;background:#eff2f0;padding:24px">
  <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;border:1px solid #e2e7e3">
    <div style="background:#0f2439;padding:20px 28px;color:#fff">
      <div style="font-size:18px;font-weight:800">Tipping Jar · admin</div>
      <div style="opacity:.8;font-size:13px;margin-top:2px">Incomplete signup alert</div>
    </div>
    <div style="padding:22px 28px;color:#0f2439">
      <table style="width:100%;border-collapse:collapse;font-size:14px">
        <tr><td style="padding:6px 0;color:#5a6b7b;width:130px">User</td><td style="padding:6px 0;font-weight:700">{username}</td></tr>
        <tr><td style="padding:6px 0;color:#5a6b7b">Email</td><td style="padding:6px 0;font-weight:700">{email}</td></tr>
        <tr><td style="padding:6px 0;color:#5a6b7b">Signed up</td><td style="padding:6px 0">{signed_up} (SAST)</td></tr>
        <tr><td style="padding:6px 0;color:#5a6b7b">Status</td><td style="padding:6px 0;color:#e0a536;font-weight:700">No creator page after {after_hours}h</td></tr>
      </table>
      <p style="margin:14px 0 0;color:#5a6b7b;font-size:13px">A one-time completion reminder was just emailed to the user.</p>
    </div>
  </div>
</div>"#
    );
    (subject, text, html)
}

async fn run_daily_report(
    pools: &Pools,
    date_override: Option<NaiveDate>,
    to_override: Option<String>,
) -> Result<Summary, AppError> {
    let report_date = match date_override {
        Some(d) => d,
        None => (Utc::now().with_timezone(&Johannesburg) - Duration::days(1)).date_naive(),
    };
    let start_local = Johannesburg
        .from_local_datetime(&report_date.and_hms_opt(0, 0, 0).unwrap())
        .single()
        .ok_or_else(|| AppError::Internal("ambiguous local midnight".into()))?;
    let start_utc: DateTime<Utc> = start_local.with_timezone(&Utc);
    let end_utc = start_utc + Duration::days(1);
    let date_label = report_date.format("%a %d %b %Y").to_string();
    tracing::info!("daily report for {date_label} ({start_utc} -> {end_utc})");

    let rows = sqlx::query(
        "SELECT creator_id, creator_name, tipper_name, amount, message, creator_net, created_at \
         FROM tips WHERE status = 'completed' AND created_at >= $1 AND created_at < $2 \
         ORDER BY creator_id, created_at",
    )
    .bind(start_utc)
    .bind(end_utc)
    .fetch_all(&pools.tips)
    .await?;

    let mut by_creator: HashMap<Uuid, Vec<TipRow>> = HashMap::new();
    for r in &rows {
        let cid: Uuid = r.try_get("creator_id")?;
        by_creator.entry(cid).or_default().push(TipRow {
            creator_name: r.try_get::<String, _>("creator_name").unwrap_or_else(|_| "Creator".into()),
            tipper: r.try_get::<String, _>("tipper_name").unwrap_or_else(|_| "Anonymous".into()),
            amount: r.try_get::<Decimal, _>("amount").unwrap_or_default(),
            net: r.try_get::<Decimal, _>("creator_net").unwrap_or_default(),
            message: r.try_get::<Option<String>, _>("message").unwrap_or(None),
            time: r
                .try_get::<DateTime<Utc>, _>("created_at")
                .map(|t| t.with_timezone(&Johannesburg).format("%H:%M").to_string())
                .unwrap_or_default(),
        });
    }

    if by_creator.is_empty() {
        tracing::info!("no completed tips for {date_label}; nothing to render");
        return Ok(Summary { date: date_label, creators: 0, rendered: 0, emailed: 0, gross: "R0.00".into() });
    }

    let ids: Vec<Uuid> = by_creator.keys().cloned().collect();
    let crows = sqlx::query("SELECT id, user_id, display_name FROM creator_profiles WHERE id = ANY($1)")
        .bind(&ids)
        .fetch_all(&pools.creators)
        .await?;
    let mut display: HashMap<Uuid, String> = HashMap::new();
    let mut user_of: HashMap<Uuid, Uuid> = HashMap::new();
    for r in &crows {
        let id: Uuid = r.try_get("id")?;
        if let Ok(name) = r.try_get::<String, _>("display_name") {
            display.insert(id, name);
        }
        if let Ok(uid) = r.try_get::<Uuid, _>("user_id") {
            user_of.insert(id, uid);
        }
    }

    let uids: Vec<Uuid> = user_of.values().cloned().collect();
    let mut email_of: HashMap<Uuid, String> = HashMap::new();
    if !uids.is_empty() {
        let urows = sqlx::query("SELECT id, email FROM users WHERE id = ANY($1)")
            .bind(&uids)
            .fetch_all(&pools.accounts)
            .await?;
        for r in &urows {
            if let (Ok(id), Ok(em)) =
                (r.try_get::<Uuid, _>("id"), r.try_get::<String, _>("email"))
            {
                email_of.insert(id, em);
            }
        }
    }

    let out_dir = env("REPORTS_DIR", "/app/reports");
    create_dir_all(&out_dir).ok();
    let email_enabled = env("REPORT_EMAIL_ENABLED", "0") == "1";

    let mut rendered = 0usize;
    let mut emailed = 0usize;
    let mut grand = Decimal::ZERO;
    for (cid, tips) in &by_creator {
        let name = display
            .get(cid)
            .filter(|s| !s.is_empty())
            .cloned()
            .unwrap_or_else(|| tips[0].creator_name.clone());
        let gross: Decimal = tips.iter().map(|t| t.amount).sum();
        let net: Decimal = tips.iter().map(|t| t.net).sum();
        grand += gross;
        let email = to_override
            .clone()
            .or_else(|| user_of.get(cid).and_then(|u| email_of.get(u)).cloned());
        let safe: String = name
            .chars()
            .map(|c| if c.is_alphanumeric() { c } else { '_' })
            .collect();
        let path = format!("{out_dir}/{safe}-{report_date}.pdf");

        match build_pdf(&name, &date_label, tips, gross, net, &path) {
            Ok(()) => {
                rendered += 1;
                match (&email, email_enabled) {
                    (Some(to), true) => {
                        let pdf_bytes = std::fs::read(&path).unwrap_or_default();
                        let args = EmailArgs {
                            to: to.clone(),
                            display: name.clone(),
                            date_label: date_label.clone(),
                            n_tips: tips.len(),
                            gross: money(gross),
                            net: money(net),
                            filename: format!("tipping-jar-report-{report_date}.pdf"),
                            pdf: pdf_bytes,
                        };
                        // lettre's SMTP transport is blocking — keep the runtime free.
                        let sent = tokio::task::spawn_blocking(move || send_report_email(args))
                            .await
                            .unwrap_or_else(|e| Err(format!("join error: {e}")));
                        match sent {
                            Ok(()) => {
                                emailed += 1;
                                tracing::info!("emailed {to} — {name}, {} tip(s)", tips.len());
                            }
                            Err(e) => tracing::error!("email failed for {name} <{to}>: {e}"),
                        }
                    }
                    (Some(to), false) => {
                        tracing::info!("rendered {path} for {name} <{to}> — email delivery disabled")
                    }
                    (None, _) => tracing::warn!("rendered {path} for {name} — no email on file"),
                }
            }
            Err(e) => tracing::error!("pdf failed for {name}: {e}"),
        }
    }

    Ok(Summary {
        date: date_label,
        creators: by_creator.len(),
        rendered,
        emailed,
        gross: money(grand),
    })
}

// ── Email delivery (lettre, STARTTLS) ────────────────────────────────────────

struct EmailArgs {
    to: String,
    display: String,
    date_label: String,
    n_tips: usize,
    gross: String,
    net: String,
    filename: String,
    pdf: Vec<u8>,
}

/// Shared STARTTLS mailer from SMTP_* env.
fn build_mailer() -> Result<(SmtpTransport, String), String> {
    let host = env("SMTP_HOST", "mail.tippingjar.co.za");
    let port: u16 = env("SMTP_PORT", "587").parse().unwrap_or(587);
    let user = env("SMTP_USER", "accounts@tippingjar.co.za");
    let pass = env("SMTP_PASS", "");
    if pass.is_empty() {
        return Err("SMTP_PASS is not set".into());
    }
    let from = env("SMTP_FROM", "Tipping Jar <accounts@tippingjar.co.za>");
    let mailer = SmtpTransport::starttls_relay(&host)
        .map_err(|e| format!("smtp relay: {e}"))?
        .port(port)
        .credentials(Credentials::new(user, pass))
        .build();
    Ok((mailer, from))
}

/// Plain HTML email (no attachment) — signup reminders, admin alerts.
fn send_html_email(to: &str, subject: &str, text: &str, html: &str) -> Result<(), String> {
    let (mailer, from) = build_mailer()?;
    let message = Message::builder()
        .from(from.parse().map_err(|e| format!("bad SMTP_FROM: {e}"))?)
        .to(to.parse().map_err(|e| format!("bad recipient: {e}"))?)
        .subject(subject)
        .multipart(
            MultiPart::alternative()
                .singlepart(SinglePart::plain(text.to_string()))
                .singlepart(SinglePart::html(html.to_string())),
        )
        .map_err(|e| format!("build message: {e}"))?;
    mailer.send(&message).map_err(|e| format!("smtp send: {e}"))?;
    Ok(())
}

fn send_report_email(a: EmailArgs) -> Result<(), String> {
    let (mailer, from) = build_mailer()?;
    let text = format!(
        "Hi {}, you received {} tip(s) totalling {} ({} to you) on {}. The full statement is attached as a PDF.",
        a.display, a.n_tips, a.gross, a.net, a.date_label
    );
    let html = email_html(&a);

    let message = Message::builder()
        .from(from.parse().map_err(|e| format!("bad SMTP_FROM: {e}"))?)
        .to(a.to.parse().map_err(|e| format!("bad recipient: {e}"))?)
        .subject(format!(
            "Your Tipping Jar report — {} from {} tip(s) · {}",
            a.net, a.n_tips, a.date_label
        ))
        .multipart(
            MultiPart::mixed()
                .multipart(
                    MultiPart::alternative()
                        .singlepart(SinglePart::plain(text))
                        .singlepart(SinglePart::html(html)),
                )
                .singlepart(
                    Attachment::new(a.filename).body(
                        a.pdf,
                        ContentType::parse("application/pdf").map_err(|e| e.to_string())?,
                    ),
                ),
        )
        .map_err(|e| format!("build message: {e}"))?;

    mailer.send(&message).map_err(|e| format!("smtp send: {e}"))?;
    Ok(())
}

fn email_html(a: &EmailArgs) -> String {
    format!(
        r#"<div style="font-family:Arial,Helvetica,sans-serif;background:#eff2f0;padding:24px">
  <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;border:1px solid #e2e7e3">
    <div style="background:#0f2439;padding:24px 28px;color:#fff">
      <div style="font-size:20px;font-weight:800">Tipping Jar</div>
      <div style="opacity:.8;font-size:14px;margin-top:2px">Daily tips report · {date}</div>
    </div>
    <div style="padding:24px 28px;color:#0f2439">
      <p style="margin:0 0 6px;font-size:16px">Hi {display},</p>
      <p style="margin:0 0 18px;color:#5a6b7b">You received <b>{n} tip(s)</b> yesterday. The full styled statement is attached as a PDF.</p>
      <table style="width:100%;border-collapse:separate;border-spacing:12px 0"><tr>
        <td style="background:#eff2f0;border-radius:12px;padding:14px;width:50%">
          <div style="font-size:11px;color:#5a6b7b;text-transform:uppercase;letter-spacing:1px">Gross</div>
          <div style="font-size:22px;font-weight:800;color:#0f2439">{gross}</div>
        </td>
        <td style="background:#eff2f0;border-radius:12px;padding:14px;width:50%">
          <div style="font-size:11px;color:#5a6b7b;text-transform:uppercase;letter-spacing:1px">You receive</div>
          <div style="font-size:22px;font-weight:800;color:#12a25c">{net}</div>
        </td>
      </tr></table>
      <a href="https://www.tippingjar.co.za/dashboard" style="display:inline-block;margin-top:20px;background:#0f2439;color:#fff;text-decoration:none;padding:12px 22px;border-radius:999px;font-weight:600">View your dashboard</a>
    </div>
    <div style="padding:16px 28px;color:#8a97a4;font-size:12px;border-top:1px solid #e2e7e3">
      You're receiving this because you have an active Tipping Jar creator page.
    </div>
  </div>
</div>"#,
        date = a.date_label,
        display = a.display,
        n = a.n_tips,
        gross = a.gross,
        net = a.net,
    )
}

// ── PDF rendering (printpdf, top-left coordinate helpers) ─────────────────────

const PAGE_H: f32 = 297.0;
const MARGIN: f32 = 16.0;
const INNER: f32 = 178.0; // 210 - 2*margin

fn rgb(r: u8, g: u8, b: u8) -> Color {
    Color::Rgb(Rgb::new(r as f32 / 255.0, g as f32 / 255.0, b as f32 / 255.0, None))
}

fn money(d: Decimal) -> String {
    format!("R{:.2}", d.to_f64().unwrap_or(0.0))
}

/// Filled rectangle, positioned from the top-left in mm.
fn fill_rect(layer: &PdfLayerReference, x: f32, y_top: f32, w: f32, h: f32, color: Color) {
    layer.set_fill_color(color);
    let y0 = PAGE_H - (y_top + h);
    let y1 = PAGE_H - y_top;
    let ring = vec![
        (Point::new(Mm(x), Mm(y1)), false),
        (Point::new(Mm(x + w), Mm(y1)), false),
        (Point::new(Mm(x + w), Mm(y0)), false),
        (Point::new(Mm(x), Mm(y0)), false),
    ];
    layer.add_polygon(Polygon {
        rings: vec![ring],
        mode: PolygonMode::Fill,
        winding_order: WindingOrder::NonZero,
    });
}

/// Horizontal hairline at a top-origin y.
fn hline(layer: &PdfLayerReference, x: f32, y_top: f32, w: f32, color: Color) {
    layer.set_outline_color(color);
    layer.set_outline_thickness(0.4);
    let y = PAGE_H - y_top;
    layer.add_line(Line {
        points: vec![
            (Point::new(Mm(x), Mm(y)), false),
            (Point::new(Mm(x + w), Mm(y)), false),
        ],
        is_closed: false,
    });
}

/// Left-aligned text with baseline at a top-origin y.
fn text(
    layer: &PdfLayerReference,
    s: &str,
    size: f32,
    x: f32,
    y_top: f32,
    font: &IndirectFontRef,
    color: Color,
) {
    layer.set_fill_color(color);
    layer.use_text(s, size, Mm(x), Mm(PAGE_H - y_top), font);
}

/// Right-aligned text (baseline y from top). Width is approximated from
/// Helvetica's average advance — fine for short currency strings.
fn text_right(
    layer: &PdfLayerReference,
    s: &str,
    size: f32,
    x_right: f32,
    y_top: f32,
    font: &IndirectFontRef,
    color: Color,
) {
    let w_mm = s.chars().count() as f32 * size * 0.55 * 0.3528;
    text(layer, s, size, x_right - w_mm, y_top, font, color);
}

fn truncate(s: &str, n: usize) -> String {
    if s.chars().count() <= n {
        s.to_string()
    } else {
        let mut out: String = s.chars().take(n.saturating_sub(1)).collect();
        out.push('…');
        out
    }
}

fn build_pdf(
    display: &str,
    date_label: &str,
    tips: &[TipRow],
    gross: Decimal,
    net: Decimal,
    path: &str,
) -> Result<(), String> {
    let (doc, page, layer_idx) =
        PdfDocument::new("Daily tips report", Mm(210.0), Mm(PAGE_H), "layer1");
    let l = doc.get_page(page).get_layer(layer_idx);
    let font = doc
        .add_builtin_font(BuiltinFont::Helvetica)
        .map_err(|e| e.to_string())?;
    let bold = doc
        .add_builtin_font(BuiltinFont::HelveticaBold)
        .map_err(|e| e.to_string())?;

    let navy = rgb(15, 36, 57);
    let mint = rgb(87, 206, 139);
    let green = rgb(18, 162, 92);
    let ink = rgb(15, 36, 57);
    let muted = rgb(90, 107, 123);
    let border = rgb(226, 231, 227);
    let canvas = rgb(239, 242, 240);
    let white = rgb(255, 255, 255);

    // Header band
    fill_rect(&l, 0.0, 0.0, 210.0, 34.0, navy.clone());
    text(&l, "Tipping Jar", 22.0, MARGIN, 16.0, &bold, white.clone());
    text(&l, "Daily tips report", 11.0, MARGIN, 25.0, &font, white.clone());
    text_right(&l, date_label, 10.0, 210.0 - MARGIN, 15.0, &font, mint);

    // Creator
    text(&l, display, 16.0, MARGIN, 47.0, &bold, ink.clone());
    text(
        &l,
        &format!("{} tip(s) received", tips.len()),
        10.0,
        MARGIN,
        54.0,
        &font,
        muted.clone(),
    );

    // Summary tiles
    let tile_w = (INNER - 8.0) / 3.0;
    let tiles = [
        ("TIPS", tips.len().to_string(), ink.clone()),
        ("GROSS", money(gross), ink.clone()),
        ("YOU RECEIVE", money(net), green.clone()),
    ];
    for (i, (label, value, col)) in tiles.iter().enumerate() {
        let x = MARGIN + i as f32 * (tile_w + 4.0);
        fill_rect(&l, x, 62.0, tile_w, 22.0, canvas.clone());
        text(&l, label, 8.0, x + 5.0, 69.0, &font, muted.clone());
        text(&l, value, 15.0, x + 5.0, 79.0, &bold, col.clone());
    }

    // Table header
    let y_head = 94.0;
    fill_rect(&l, MARGIN, y_head, INNER, 9.0, navy);
    let x_time = MARGIN + 2.0;
    let x_supp = MARGIN + 18.0;
    let x_msg = MARGIN + 58.0;
    let x_amt_r = MARGIN + 18.0 + 40.0 + 68.0 + 26.0; // 168
    let x_net_r = MARGIN + INNER; // 194
    text(&l, "Time", 9.0, x_time, y_head + 6.0, &bold, white.clone());
    text(&l, "Supporter", 9.0, x_supp, y_head + 6.0, &bold, white.clone());
    text(&l, "Message", 9.0, x_msg, y_head + 6.0, &bold, white.clone());
    text_right(&l, "Amount", 9.0, x_amt_r, y_head + 6.0, &bold, white.clone());
    text_right(&l, "You get", 9.0, x_net_r, y_head + 6.0, &bold, white.clone());

    // Rows
    let mut y = y_head + 9.0;
    let max_rows = 24usize;
    for (idx, t) in tips.iter().enumerate() {
        if idx >= max_rows {
            text(
                &l,
                &format!("+ {} more transaction(s)", tips.len() - max_rows),
                9.0,
                x_time,
                y + 5.5,
                &font,
                muted.clone(),
            );
            y += 8.0;
            break;
        }
        if idx % 2 == 1 {
            fill_rect(&l, MARGIN, y, INNER, 8.0, rgb(247, 249, 248));
        }
        let base = y + 5.4;
        text(&l, &t.time, 9.0, x_time, base, &font, muted.clone());
        text(&l, &truncate(&t.tipper, 20), 9.0, x_supp, base, &bold, ink.clone());
        text(
            &l,
            &truncate(t.message.as_deref().unwrap_or(""), 34),
            9.0,
            x_msg,
            base,
            &font,
            muted.clone(),
        );
        text_right(&l, &money(t.amount), 9.0, x_amt_r, base, &bold, ink.clone());
        text_right(&l, &money(t.net), 9.0, x_net_r, base, &bold, green.clone());
        hline(&l, MARGIN, y + 8.0, INNER, border.clone());
        y += 8.0;
    }

    // Totals
    fill_rect(&l, MARGIN, y + 1.0, INNER, 10.0, canvas);
    let tbase = y + 7.5;
    text_right(&l, "Total", 10.0, MARGIN + 126.0, tbase, &bold, ink.clone());
    text_right(&l, &money(gross), 10.0, x_amt_r, tbase, &bold, ink);
    text_right(&l, &money(net), 10.0, x_net_r, tbase, &bold, green);

    // Footer
    text(
        &l,
        "Generated by Tipping Jar  ·  tippingjar.co.za  ·  This is a summary, not a tax invoice.",
        8.0,
        MARGIN,
        286.0,
        &font,
        muted,
    );

    let file = File::create(path).map_err(|e| e.to_string())?;
    let mut buf = BufWriter::new(file);
    doc.save(&mut buf).map_err(|e| e.to_string())?;
    Ok(())
}
