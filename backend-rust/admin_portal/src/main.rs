//! Admin portal microservice — a read-only aggregator (ports the Django
//! `admin_portal` app, which has no models of its own). It owns no database;
//! instead it fans out to the other services to build a dashboard, which also
//! demonstrates the fleet's service-to-service connectivity.

use axum::extract::State;
use axum::routing::get;
use axum::{Json, Router};
use common::env;
use serde_json::{json, Value};

#[derive(Clone)]
struct AppState {
    http: reqwest::Client,
    creators_url: String,
    tips_url: String,
    support_url: String,
    payments_url: String,
}

async fn health() -> Json<Value> {
    Json(json!({ "status": "ok", "service": "admin_portal" }))
}

/// Fetch a JSON array from `url`, returning it (or an empty array on failure).
async fn fetch_array(http: &reqwest::Client, url: String) -> Result<Vec<Value>, String> {
    let resp = http
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("request failed: {e}"))?;
    if !resp.status().is_success() {
        return Err(format!("status {}", resp.status()));
    }
    let body: Value = resp.json().await.map_err(|e| format!("bad json: {e}"))?;
    Ok(body.as_array().cloned().unwrap_or_default())
}

/// A dashboard aggregated live from creators + tips + support + payments.
async fn dashboard(State(st): State<AppState>) -> Json<Value> {
    let creators_f = fetch_array(&st.http, format!("{}/creators", st.creators_url));
    let tips_f = fetch_array(&st.http, format!("{}/tips", st.tips_url));
    let contacts_f = fetch_array(&st.http, format!("{}/contact", st.support_url));
    let disputes_f = fetch_array(&st.http, format!("{}/disputes", st.support_url));

    let (creators, tips, contacts, disputes) =
        tokio::join!(creators_f, tips_f, contacts_f, disputes_f);

    // Sum completed tip amounts (amounts come back as decimal strings).
    let (tip_count, tip_total) = match &tips {
        Ok(list) => {
            let total: f64 = list
                .iter()
                .filter_map(|t| t.get("amount").and_then(|a| a.as_str()))
                .filter_map(|s| s.parse::<f64>().ok())
                .sum();
            (list.len() as i64, total)
        }
        Err(_) => (0, 0.0),
    };

    let section = |res: &Result<Vec<Value>, String>| match res {
        Ok(list) => json!({ "ok": true, "count": list.len() }),
        Err(e) => json!({ "ok": false, "error": e }),
    };

    Json(json!({
        "service": "admin_portal",
        "sources": {
            "creators": section(&creators),
            "contacts": section(&contacts),
            "disputes": section(&disputes),
            "tips": match &tips {
                Ok(_) => json!({ "ok": true, "count": tip_count, "total_amount": format!("{:.2}", tip_total) }),
                Err(e) => json!({ "ok": false, "error": e }),
            },
        },
        "payments_service": st.payments_url,
        "recent_tips": tips.unwrap_or_default().into_iter().take(5).collect::<Vec<_>>(),
    }))
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let state = AppState {
        http: reqwest::Client::new(),
        creators_url: env("CREATORS_URL", "http://localhost:8082"),
        tips_url: env("TIPS_URL", "http://localhost:8084"),
        support_url: env("SUPPORT_URL", "http://localhost:8088"),
        payments_url: env("PAYMENTS_URL", "http://localhost:8083"),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/dashboard", get(dashboard))
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
