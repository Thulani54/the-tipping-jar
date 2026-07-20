//! Minimal HS256 JWT helpers. Only the `accounts` service signs tokens; other
//! services verify them by calling `accounts`, so the signing secret never has
//! to be shared across the fleet.

use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    /// Subject — the user id.
    pub sub: String,
    pub email: String,
    pub role: String,
    /// Expiry as a UNIX timestamp (seconds).
    pub exp: usize,
}

pub fn encode_jwt(
    user_id: &str,
    email: &str,
    role: &str,
    secret: &str,
    ttl_secs: i64,
) -> Result<String, jsonwebtoken::errors::Error> {
    let exp = (chrono::Utc::now().timestamp() + ttl_secs) as usize;
    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        exp,
    };
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
}

pub fn decode_jwt(token: &str, secret: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )?;
    Ok(data.claims)
}
