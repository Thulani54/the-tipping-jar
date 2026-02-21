"""
SMSPortal integration helpers.

Sending pattern:
    GET {SMS_PORTAL_ENDPOINT}?Type=sendparam&username=...&password=...&numto=...&data1=...

Credits check:
    GET {SMS_PORTAL_ENDPOINT}?Type=credits&username=...&password=...
"""

import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

_ENDPOINT = lambda: getattr(settings, "SMS_PORTAL_ENDPOINT", "https://api.smsportal.com/api5/http5.aspx")
_USER = lambda: getattr(settings, "SMS_PORTAL_USERNAME", "")
_PASS = lambda: getattr(settings, "SMS_PORTAL_PASSWORD", "")


def send_sms(phone_number: str, message: str) -> dict:
    """
    Send a single SMS via SMSPortal.

    Args:
        phone_number: Recipient number in international format, e.g. "+27821234567".
        message:      Plain-text SMS body (max ~160 chars for single segment).

    Returns:
        dict with keys ``success`` (bool) and ``response`` (str) or ``error`` (str).
    """
    endpoint = _ENDPOINT()
    username = _USER()
    password = _PASS()

    if not endpoint or not username or not password:
        logger.warning("SMS Portal not configured — skipping SMS to %s", phone_number[:6])
        return {"success": False, "error": "SMS Portal not configured."}

    params = {
        "Type": "sendparam",
        "username": username,
        "password": password,
        "numto": phone_number,
        "data1": message,
    }

    try:
        response = requests.get(endpoint, params=params, timeout=30)
        response.raise_for_status()
        body = response.text.strip()
        logger.info("SMSPortal response for %s: %s", phone_number[:6], body[:80])

        # SMSPortal returns a pipe-delimited string; check for error code 0 = success
        success = "ErrCode: 0" in body or body.startswith("0|") or "OK" in body.upper()
        if success:
            return {"success": True, "response": body}
        return {"success": False, "error": body}

    except requests.RequestException as exc:
        logger.error("SMSPortal send_sms error: %s", exc)
        return {"success": False, "error": str(exc)}


def send_otp_via_sms(phone_number: str, otp: str) -> dict:
    """
    Send a 6-digit OTP via SMS.

    Returns same dict as :func:`send_sms`.
    """
    message = f"Your TippingJar verification code is: {otp}. Valid for 10 minutes. Do not share this code."
    return send_sms(phone_number, message)


def get_sms_credits() -> dict:
    """
    Query remaining SMS credit balance from SMSPortal.

    Returns:
        dict with ``success`` (bool), ``credits`` (float or None), ``raw`` (str).
    """
    endpoint = _ENDPOINT()
    username = _USER()
    password = _PASS()

    if not endpoint or not username or not password:
        return {"success": False, "credits": None, "raw": "Not configured"}

    params = {
        "Type": "credits",
        "username": username,
        "password": password,
    }

    try:
        response = requests.get(endpoint, params=params, timeout=15)
        response.raise_for_status()
        body = response.text.strip()
        logger.info("SMSPortal credits response: %s", body[:120])

        # Typical response: "ErrCode: 0 | ErrDescription: OK | CreditBalance: 1234.56"
        credits = None
        for part in body.split("|"):
            part = part.strip()
            if "CreditBalance" in part or "Credit" in part:
                try:
                    credits = float(part.split(":")[-1].strip())
                except ValueError:
                    pass

        return {"success": True, "credits": credits, "raw": body}

    except requests.RequestException as exc:
        logger.error("SMSPortal get_credits error: %s", exc)
        return {"success": False, "credits": None, "raw": str(exc)}
