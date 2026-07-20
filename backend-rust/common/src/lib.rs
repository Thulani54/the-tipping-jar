//! Shared building blocks for every Tipping Jar microservice:
//! a uniform JSON error type, JWT helpers and small env utilities.

use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde_json::json;

pub mod jwt;

/// One error type shared by all services. Each variant maps to an HTTP status
/// and renders as `{"error": "<message>"}` so clients see a consistent shape.
#[derive(Debug)]
pub enum AppError {
    NotFound(String),
    BadRequest(String),
    Unauthorized(String),
    Conflict(String),
    /// A downstream service call failed (e.g. tips -> payments).
    Upstream(String),
    Internal(String),
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AppError::NotFound(m) => write!(f, "not found: {m}"),
            AppError::BadRequest(m) => write!(f, "bad request: {m}"),
            AppError::Unauthorized(m) => write!(f, "unauthorized: {m}"),
            AppError::Conflict(m) => write!(f, "conflict: {m}"),
            AppError::Upstream(m) => write!(f, "upstream: {m}"),
            AppError::Internal(m) => write!(f, "internal: {m}"),
        }
    }
}

impl std::error::Error for AppError {}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, msg) = match self {
            AppError::NotFound(m) => (StatusCode::NOT_FOUND, m),
            AppError::BadRequest(m) => (StatusCode::BAD_REQUEST, m),
            AppError::Unauthorized(m) => (StatusCode::UNAUTHORIZED, m),
            AppError::Conflict(m) => (StatusCode::CONFLICT, m),
            AppError::Upstream(m) => (StatusCode::BAD_GATEWAY, m),
            AppError::Internal(m) => (StatusCode::INTERNAL_SERVER_ERROR, m),
        };
        (status, Json(json!({ "error": msg }))).into_response()
    }
}

impl From<sqlx::Error> for AppError {
    fn from(e: sqlx::Error) -> Self {
        match e {
            sqlx::Error::RowNotFound => AppError::NotFound("resource not found".into()),
            other => AppError::Internal(format!("database error: {other}")),
        }
    }
}

impl From<reqwest::Error> for AppError {
    fn from(e: reqwest::Error) -> Self {
        AppError::Upstream(format!("service call failed: {e}"))
    }
}

impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(e: jsonwebtoken::errors::Error) -> Self {
        AppError::Unauthorized(format!("invalid token: {e}"))
    }
}

/// Read an environment variable, falling back to `default` when unset.
pub fn env(key: &str, default: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| default.to_string())
}
