"""
Paystack API wrapper for TippingJar.

All monetary amounts going TO Paystack must be in kobo (smallest ZAR unit):
    R10.00 → 1000 kobo

Fee structure per tip:
    - Platform fee (PLATFORM_FEE_PERCENT, default 3%) → TippingJar master account
    - Service fee (SERVICE_FEE_PERCENT, default 3%) → deducted from creator's share
      by Paystack when bearer="subaccount"
    - Creator receives: amount × (1 - platform_fee%)

Subaccount split:
    When creating a subaccount with percentage_charge=3 and bearer="subaccount":
      - 3% of each transaction goes to master account
      - Paystack's own fees (~3%) are deducted from the subaccount's share
      - Creator receives approximately 94% net
"""

import hashlib
import hmac
import uuid

import requests
from django.conf import settings

_BASE = "https://api.paystack.co"


def _headers() -> dict:
    return {
        "Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}",
        "Content-Type": "application/json",
    }


# ── Subaccount ────────────────────────────────────────────────────────────────

def create_subaccount(
    business_name: str,
    settlement_bank: str,   # Paystack bank code, e.g. "632005" for ABSA
    account_number: str,
    percentage_charge: float = None,  # % that goes to master account
) -> dict:
    """
    Create a Paystack subaccount for a creator.

    Returns the full Paystack response dict.
    On error raises RuntimeError with the Paystack message.
    """
    if percentage_charge is None:
        percentage_charge = settings.PLATFORM_FEE_PERCENT

    payload = {
        "business_name": business_name,
        "settlement_bank": settlement_bank,
        "account_number": account_number,
        "percentage_charge": percentage_charge,
    }
    resp = requests.post(f"{_BASE}/subaccount", json=payload, headers=_headers(), timeout=15)
    data = resp.json()
    if not data.get("status"):
        raise RuntimeError(data.get("message", "Paystack subaccount creation failed."))
    return data["data"]


def get_subaccount(subaccount_code: str) -> dict:
    """Fetch subaccount details by code."""
    resp = requests.get(f"{_BASE}/subaccount/{subaccount_code}", headers=_headers(), timeout=15)
    data = resp.json()
    if not data.get("status"):
        raise RuntimeError(data.get("message", "Paystack subaccount fetch failed."))
    return data["data"]


def create_split(name: str, creator_subaccount_code: str, platform_subaccount_code: str, platform_share: float = 3.0) -> dict:
    """
    Create a Paystack transaction split for a creator.

    Split structure:
        - platform_subaccount  → platform_share %  (IMALI BADALA — TippingJar fee)
        - creator_subaccount   → (100 - platform_share) %
        - main account         → 0%
        - bearer               → creator subaccount (bears Paystack processing fees)

    Returns the split data dict including split_code (SPL_xxxx).
    Raises RuntimeError on failure.
    """
    creator_share = round(100.0 - platform_share, 4)
    payload = {
        "name": name,
        "type": "percentage",
        "currency": "ZAR",
        "subaccounts": [
            {"subaccount": platform_subaccount_code, "share": platform_share},
            {"subaccount": creator_subaccount_code,  "share": creator_share},
        ],
        "bearer_type": "subaccount",
        "bearer_subaccount": creator_subaccount_code,
    }
    resp = requests.post(f"{_BASE}/split", json=payload, headers=_headers(), timeout=15)
    data = resp.json()
    if not data.get("status"):
        raise RuntimeError(data.get("message", "Paystack split creation failed."))
    return data["data"]


def resolve_account(account_number: str, bank_code: str) -> dict:
    """
    Validate a bank account number and return the account name.

    Returns dict with keys: account_number, account_name.
    Raises RuntimeError if the account cannot be resolved.
    """
    resp = requests.get(
        f"{_BASE}/bank/resolve",
        params={"account_number": account_number, "bank_code": bank_code},
        headers=_headers(),
        timeout=15,
    )
    data = resp.json()
    if not data.get("status"):
        raise RuntimeError(data.get("message", "Could not verify account. Check the number and bank."))
    return data["data"]


# ── Transaction ───────────────────────────────────────────────────────────────

def initialize_transaction(
    email: str,
    amount_zar: float,
    reference: str,
    subaccount_code: str | None = None,
    split_code: str | None = None,
    callback_url: str | None = None,
    metadata: dict | None = None,
) -> dict:
    """
    Initialize a Paystack payment transaction.

    Prefer split_code (SPL_xxxx) over subaccount_code when both are set —
    the split already encodes the creator subaccount plus the platform share.

    Returns dict with keys: authorization_url, access_code, reference.
    """
    amount_kobo = int(round(amount_zar * 100))

    payload: dict = {
        "email": email,
        "amount": amount_kobo,
        "reference": reference,
        "currency": "ZAR",
    }

    if split_code:
        # Transaction split handles routing to platform + creator subaccounts.
        # Bearer is already encoded in the split (creator bears Paystack fees).
        payload["split_code"] = split_code
    elif subaccount_code:
        payload["subaccount"] = subaccount_code
        payload["bearer"] = "subaccount"

    if callback_url:
        payload["callback_url"] = callback_url

    if metadata:
        payload["metadata"] = metadata

    resp = requests.post(
        f"{_BASE}/transaction/initialize",
        json=payload,
        headers=_headers(),
        timeout=15,
    )
    data = resp.json()
    if not data.get("status"):
        raise RuntimeError(data.get("message", "Paystack transaction initialization failed."))
    return data["data"]


def verify_transaction(reference: str) -> dict:
    """
    Verify a transaction by reference.

    Returns the full transaction data dict.
    Raises RuntimeError if verification fails.
    """
    resp = requests.get(
        f"{_BASE}/transaction/verify/{reference}",
        headers=_headers(),
        timeout=15,
    )
    data = resp.json()
    if not data.get("status"):
        raise RuntimeError(data.get("message", "Paystack verification failed."))
    return data["data"]


# ── Webhook signature ─────────────────────────────────────────────────────────

def verify_webhook_signature(payload_bytes: bytes, signature: str) -> bool:
    """
    Verify that a webhook request came from Paystack.

    Paystack signs with HMAC-SHA512 using your webhook secret.
    """
    secret = settings.PAYSTACK_WEBHOOK_SECRET
    if not secret:
        # In dev mode without webhook secret, allow all (unsafe for prod)
        return True
    computed = hmac.new(
        secret.encode("utf-8"),
        msg=payload_bytes,
        digestmod=hashlib.sha512,
    ).hexdigest()
    return hmac.compare_digest(computed, signature)


# ── Recurring charge ──────────────────────────────────────────────────────────

def charge_authorization(
    email: str,
    amount_zar: float,
    authorization_code: str,
    reference: str,
) -> dict:
    """
    Re-charge a saved Paystack card using a stored authorization code.

    Used for monthly pledge re-billing.
    Returns the transaction data dict on success.
    Raises RuntimeError if the charge fails.
    """
    payload = {
        "email": email,
        "amount": int(round(amount_zar * 100)),
        "authorization_code": authorization_code,
        "reference": reference,
        "currency": "ZAR",
    }
    resp = requests.post(
        f"{_BASE}/transaction/charge_authorization",
        json=payload,
        headers=_headers(),
        timeout=15,
    )
    data = resp.json()
    if not data.get("status"):
        raise RuntimeError(data.get("message", "Paystack charge_authorization failed."))
    return data["data"]


# ── Reference generation ──────────────────────────────────────────────────────

def generate_reference(tip_id: int | None = None) -> str:
    """Generate a unique Paystack transaction reference."""
    suffix = str(tip_id) if tip_id else uuid.uuid4().hex[:8]
    return f"TJ-{suffix}-{uuid.uuid4().hex[:8]}"


# ── Fee calculation ───────────────────────────────────────────────────────────

def calculate_fees(amount_zar: float) -> dict:
    """
    Given a tip amount in ZAR, return a breakdown of fees.

    Returns:
        platform_fee   — amount going to TippingJar
        service_fee    — Paystack processing fee borne by creator
        creator_net    — what the creator ultimately receives
        total_fee      — platform_fee + service_fee
    """
    platform_pct = settings.PLATFORM_FEE_PERCENT / 100
    service_pct  = settings.SERVICE_FEE_PERCENT  / 100

    platform_fee = round(amount_zar * platform_pct, 2)
    service_fee  = round(amount_zar * service_pct,  2)
    creator_net  = round(amount_zar - platform_fee - service_fee, 2)

    return {
        "platform_fee":   platform_fee,
        "service_fee":    service_fee,
        "creator_net":    creator_net,
        "total_fee":      round(platform_fee + service_fee, 2),
        "platform_pct":   settings.PLATFORM_FEE_PERCENT,
        "service_pct":    settings.SERVICE_FEE_PERCENT,
    }
