"""
Email helpers for the support app.

All outbound mail uses accounts@ for SMTP auth (configured in settings).
Dispute / contact confirmations set the From header to no-reply@.
Support notifications land in support@.
"""
import logging

from django.conf import settings
from django.core.mail import EmailMultiAlternatives

logger = logging.getLogger(__name__)


def _no_reply():
    return getattr(settings, "NO_REPLY_EMAIL", "no-reply@tippingjar.co.za")


def _support():
    return getattr(settings, "SUPPORT_EMAIL", "support@tippingjar.co.za")


# ─── Contact form ─────────────────────────────────────────────────────────────

def send_contact_to_support(contact):
    """Forward the contact form to the support inbox."""
    body = (
        f"New contact form submission\n"
        f"{'─' * 40}\n"
        f"Name:    {contact.name}\n"
        f"Email:   {contact.email}\n"
        f"Subject: {contact.get_subject_display()}\n\n"
        f"{contact.message}\n\n"
        f"Reply directly to: {contact.email}"
    )
    msg = EmailMultiAlternatives(
        subject=f"[Contact] {contact.get_subject_display()} — {contact.name}",
        body=body,
        from_email=_no_reply(),
        to=[_support()],
        reply_to=[contact.email],
    )
    msg.send(fail_silently=True)


def send_contact_confirmation(contact):
    """Acknowledgement email to the person who submitted the form."""
    body = (
        f"Hi {contact.name},\n\n"
        f"Thanks for reaching out! We received your message and will get back to you "
        f"within 1–2 business days.\n\n"
        f"Your message:\n"
        f"  Subject: {contact.get_subject_display()}\n"
        f"  \"{contact.message[:300]}{'...' if len(contact.message) > 300 else ''}\"\n\n"
        f"If your matter is urgent you can reply to this email directly.\n\n"
        f"— The TippingJar Support Team\n"
        f"  support@tippingjar.co.za\n"
        f"  tippingjar.co.za"
    )
    html = f"""
<div style="font-family:Inter,sans-serif;max-width:560px;margin:auto;padding:32px;background:#0A0F0D;color:#E2E8F0;border-radius:12px;">
  <h2 style="color:#00C896;margin-bottom:4px;">We got your message ✓</h2>
  <p style="color:#7A9088;font-size:14px;">Hi {contact.name}, thanks for reaching out.</p>
  <p style="font-size:15px;line-height:1.6;">
    We received your enquiry and will get back to you within <strong>1–2 business days</strong>.
  </p>
  <div style="background:#111A16;border:1px solid #1E2E26;border-radius:8px;padding:16px;margin:20px 0;">
    <p style="margin:0;font-size:13px;color:#7A9088;">Subject: {contact.get_subject_display()}</p>
    <p style="margin:8px 0 0;font-size:14px;">{contact.message[:300]}{'...' if len(contact.message) > 300 else ''}</p>
  </div>
  <p style="font-size:13px;color:#7A9088;">If urgent, reply to this email.</p>
  <hr style="border-color:#1E2E26;margin:24px 0;">
  <p style="font-size:12px;color:#7A9088;margin:0;">
    TippingJar · <a href="https://tippingjar.co.za" style="color:#00C896;">tippingjar.co.za</a> · support@tippingjar.co.za
  </p>
</div>"""

    msg = EmailMultiAlternatives(
        subject="We received your message — TippingJar Support",
        body=body,
        from_email=_support(),
        to=[contact.email],
    )
    msg.attach_alternative(html, "text/html")
    msg.send(fail_silently=True)


# ─── Tip thank-you ────────────────────────────────────────────────────────────

_ANON_EMAIL = "anonymous@tippingjar.co.za"


def send_tip_thank_you(tip):
    """Send a thank-you email to the tipper after a successful payment."""
    if not tip.tipper_email or tip.tipper_email == _ANON_EMAIL:
        logger.info("send_tip_thank_you: skipped tip=%s (no real tipper email)", tip.id)
        return

    creator = tip.creator
    tipper_name = tip.tipper_name or "there"
    amount = f"R{tip.amount:.2f}"
    jar_name = tip.jar.name if tip.jar else None
    creator_page = f"https://www.tippingjar.co.za/creator/{creator.slug}"
    dispute_url = f"https://www.tippingjar.co.za/dispute?ref={tip.paystack_reference}"

    custom_msg = (creator.thank_you_message.strip()
                  if creator.thank_you_message.strip()
                  else "Thank you so much for the support — it truly means the world to me!")

    subject = f"{creator.display_name} thanks you for your tip 💚"

    jar_line_text = f" into the '{jar_name}' jar" if jar_name else ""

    body = (
        f"Hi {tipper_name},\n\n"
        f"You sent a {amount} tip{jar_line_text} to {creator.display_name}.\n\n"
        f"{custom_msg}\n\n"
        f"Visit {creator.display_name}'s page: {creator_page}\n\n"
        f"Transaction reference: {tip.paystack_reference}\n"
        f"You have 24 hours to dispute this transaction: {dispute_url}\n\n"
        f"— The TippingJar Team\n"
        f"  www.tippingjar.co.za"
    )

    html = f"""
<div style="font-family:Inter,sans-serif;max-width:560px;margin:auto;padding:32px;background:#0A0F0D;color:#E2E8F0;border-radius:12px;">
  <div style="text-align:center;margin-bottom:28px;">
    <span style="font-size:40px;">💚</span>
    <h2 style="color:#00C896;margin:8px 0 4px;">{creator.display_name} says thank you!</h2>
    <p style="color:#7A9088;font-size:14px;margin:0;">Hi {tipper_name}, your tip was received.</p>
  </div>
  <div style="background:#111A16;border:1px solid #1E2E26;border-radius:10px;padding:20px;margin:0 0 24px;">
    <p style="margin:0;font-size:13px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">Tip amount</p>
    <p style="margin:4px 0 0;font-size:28px;font-weight:800;color:#00C896;">{amount}</p>
    {'<p style="margin:6px 0 0;font-size:13px;color:#7A9088;">Jar: <strong style=\\"color:#E2E8F0;\\">' + jar_name + '</strong></p>' if jar_name else ''}
  </div>
  <div style="background:#0D1A12;border-left:3px solid #00C896;padding:16px 20px;border-radius:0 8px 8px 0;margin-bottom:24px;">
    <p style="margin:0;font-size:15px;line-height:1.7;color:#E2E8F0;font-style:italic;">"{custom_msg}"</p>
    <p style="margin:10px 0 0;font-size:13px;color:#7A9088;">— {creator.display_name}</p>
  </div>
  <a href="{creator_page}" style="display:block;text-align:center;background:#00C896;color:#fff;text-decoration:none;padding:14px 28px;border-radius:36px;font-weight:700;font-size:15px;margin-bottom:20px;">
    Visit {creator.display_name}'s page →
  </a>
  <div style="background:#0D1209;border:1px solid #1E2E26;border-radius:10px;padding:16px 20px;margin-bottom:24px;">
    <p style="margin:0;font-size:12px;color:#7A9088;">
      Transaction ref: <strong style="color:#E2E8F0;font-family:monospace;">{tip.paystack_reference}</strong>
    </p>
    <p style="margin:8px 0 0;font-size:12px;color:#7A9088;line-height:1.6;">
      Something wrong? You have <strong style="color:#E2E8F0;">24 hours</strong> from the time of payment to dispute this transaction.
    </p>
    <a href="{dispute_url}" style="display:inline-block;margin-top:12px;background:transparent;color:#94A3A8;text-decoration:none;padding:8px 16px;border-radius:36px;font-weight:600;font-size:12px;border:1px solid #2E3A32;">
      Dispute this transaction →
    </a>
  </div>
  <hr style="border-color:#1E2E26;margin:0 0 16px;">
  <p style="font-size:12px;color:#7A9088;margin:0;text-align:center;">
    TippingJar · <a href="https://www.tippingjar.co.za" style="color:#00C896;">www.tippingjar.co.za</a>
  </p>
</div>"""

    msg = EmailMultiAlternatives(
        subject=subject,
        body=body,
        from_email=_no_reply(),
        to=[tip.tipper_email],
    )
    msg.attach_alternative(html, "text/html")
    try:
        msg.send(fail_silently=False)
        logger.info("send_tip_thank_you: sent to %s for tip=%s", tip.tipper_email, tip.id)
    except Exception as exc:
        logger.error("send_tip_thank_you: FAILED for tip=%s to=%s error=%s", tip.id, tip.tipper_email, exc)


# ─── Disputes ─────────────────────────────────────────────────────────────────

def send_dispute_confirmation(dispute):
    """Send the tracking link to the disputer + notify support."""
    url = dispute.tracking_url
    ref = dispute.reference

    # ── To user ──────────────────────────────────────────────────────────────
    body = (
        f"Hi {dispute.name},\n\n"
        f"Your dispute has been received and assigned reference {ref}.\n\n"
        f"Track your dispute status here:\n  {url}\n\n"
        f"Details:\n"
        f"  Reason:      {dispute.get_reason_display()}\n"
        f"  Description: {dispute.description[:200]}\n"
        f"  Status:      Open\n\n"
        f"Our team will review your case within 2 business days and update you via email.\n\n"
        f"— TippingJar Support\n"
        f"  support@tippingjar.co.za"
    )
    html = f"""
<div style="font-family:Inter,sans-serif;max-width:560px;margin:auto;padding:32px;background:#0A0F0D;color:#E2E8F0;border-radius:12px;">
  <h2 style="color:#00C896;margin-bottom:4px;">Dispute received ✓</h2>
  <p style="color:#7A9088;font-size:14px;">Reference: <strong style="color:#E2E8F0;">{ref}</strong></p>
  <p style="font-size:15px;line-height:1.6;">
    Hi {dispute.name}, we've logged your dispute and will review it within <strong>2 business days</strong>.
  </p>
  <div style="background:#111A16;border:1px solid #1E2E26;border-radius:8px;padding:16px;margin:20px 0;">
    <p style="margin:0;font-size:12px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">Reason</p>
    <p style="margin:4px 0 12px;font-size:14px;">{dispute.get_reason_display()}</p>
    <p style="margin:0;font-size:12px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">Description</p>
    <p style="margin:4px 0 0;font-size:14px;">{dispute.description[:200]}{'...' if len(dispute.description) > 200 else ''}</p>
  </div>
  <a href="{url}" style="display:inline-block;background:#00C896;color:#fff;text-decoration:none;padding:12px 28px;border-radius:36px;font-weight:700;font-size:14px;margin:8px 0;">
    Track my dispute →
  </a>
  <p style="font-size:12px;color:#7A9088;margin-top:8px;">Or copy this link: {url}</p>
  <hr style="border-color:#1E2E26;margin:24px 0;">
  <p style="font-size:12px;color:#7A9088;margin:0;">
    TippingJar · <a href="https://tippingjar.co.za" style="color:#00C896;">tippingjar.co.za</a> · support@tippingjar.co.za
  </p>
</div>"""

    msg = EmailMultiAlternatives(
        subject=f"Dispute {ref} received — TippingJar",
        body=body,
        from_email=_no_reply(),
        to=[dispute.email],
        reply_to=[_support()],
    )
    msg.attach_alternative(html, "text/html")
    msg.send(fail_silently=True)

    # ── Notify support team ───────────────────────────────────────────────────
    notify_body = (
        f"New dispute filed\n"
        f"{'─' * 40}\n"
        f"Reference:   {ref}\n"
        f"Name:        {dispute.name}\n"
        f"Email:       {dispute.email}\n"
        f"Reason:      {dispute.get_reason_display()}\n"
        f"Tip ref:     {dispute.tip_ref or 'N/A'}\n"
        f"Description: {dispute.description}\n\n"
        f"Track: {url}"
    )
    EmailMultiAlternatives(
        subject=f"[Dispute] {ref} — {dispute.get_reason_display()}",
        body=notify_body,
        from_email=_no_reply(),
        to=[_support()],
        reply_to=[dispute.email],
    ).send(fail_silently=True)


# ─── Creator lifecycle emails ──────────────────────────────────────────────────

_BASE_URL = "https://www.tippingjar.co.za"


def _creator_email_wrapper(inner_html: str) -> str:
    """Shared outer layout for all creator-facing emails."""
    return f"""
<div style="font-family:Inter,sans-serif;max-width:580px;margin:auto;background:#0A0F0D;border-radius:14px;overflow:hidden;">
  <div style="background:#0D1A12;border-bottom:1px solid #1E2E26;padding:24px 32px;">
    <span style="font-size:22px;font-weight:800;color:#00C896;letter-spacing:-0.5px;">TippingJar</span>
  </div>
  <div style="padding:32px 32px 24px;">
    {inner_html}
  </div>
  <div style="border-top:1px solid #1E2E26;padding:16px 32px;text-align:center;">
    <p style="margin:0;font-size:12px;color:#4A6358;">
      TippingJar · <a href="{_BASE_URL}" style="color:#00C896;text-decoration:none;">{_BASE_URL.replace("https://","")}</a>
      · <a href="mailto:support@tippingjar.co.za" style="color:#4A6358;text-decoration:none;">support@tippingjar.co.za</a>
    </p>
  </div>
</div>"""


def _btn(text: str, url: str) -> str:
    return (
        f'<a href="{url}" style="display:inline-block;background:#00C896;color:#fff;'
        f'text-decoration:none;padding:13px 28px;border-radius:36px;font-weight:700;'
        f'font-size:14px;margin-top:20px;">{text}</a>'
    )


def send_creator_welcome(creator) -> None:
    """Welcome email sent when a new CreatorProfile is created."""
    page_url = f"{_BASE_URL}/creator/{creator.slug}"
    dashboard_url = f"{_BASE_URL}/dashboard"

    inner = f"""
<h2 style="color:#00C896;margin:0 0 4px;font-size:22px;">Welcome to TippingJar, {creator.display_name}! 🎉</h2>
<p style="color:#7A9088;margin:0 0 20px;font-size:14px;">Your creator page is live and ready.</p>

<p style="font-size:15px;line-height:1.7;color:#E2E8F0;margin:0 0 16px;">
  Fans can now send you tips instantly — no account needed on their side.
  Here's how to get started:
</p>

<div style="background:#111A16;border:1px solid #1E2E26;border-radius:10px;padding:20px;margin-bottom:20px;">
  <p style="margin:0 0 10px;font-size:13px;color:#7A9088;font-weight:600;text-transform:uppercase;letter-spacing:.8px;">Your next steps</p>
  <ul style="margin:0;padding-left:20px;color:#E2E8F0;font-size:14px;line-height:2;">
    <li>Share your tip page link with fans</li>
    <li>Set a monthly tip goal to motivate supporters</li>
    <li>Add your bank details to receive payouts</li>
    <li>Create tip jars for specific goals</li>
  </ul>
</div>

<div style="background:#0D1A12;border:1px solid #1E2E26;border-radius:10px;padding:16px 20px;margin-bottom:8px;">
  <p style="margin:0;font-size:12px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">Your tip page</p>
  <a href="{page_url}" style="color:#00C896;font-size:15px;font-weight:600;text-decoration:none;">{page_url.replace("https://","")}</a>
</div>

{_btn("Open your dashboard →", dashboard_url)}
"""

    html = _creator_email_wrapper(inner)
    body = (
        f"Welcome to TippingJar, {creator.display_name}!\n\n"
        f"Your creator page is live: {page_url}\n\n"
        f"— The TippingJar Team"
    )
    msg = EmailMultiAlternatives(
        subject=f"Welcome to TippingJar, {creator.display_name}! 🎉",
        body=body,
        from_email=_no_reply(),
        to=[creator.user.email],
    )
    msg.attach_alternative(html, "text/html")
    try:
        msg.send(fail_silently=False)
        logger.info("send_creator_welcome: sent to %s", creator.user.email)
    except Exception as exc:
        logger.error("send_creator_welcome: FAILED creator=%s error=%s", creator.id, exc)


def send_first_tip_email(creator, tip) -> None:
    """Congratulations email on receiving first ever tip."""
    dashboard_url = f"{_BASE_URL}/dashboard"
    amount = f"R{tip.amount:.2f}"
    tipper = tip.tipper_name or "Someone"

    inner = f"""
<div style="text-align:center;margin-bottom:28px;">
  <span style="font-size:48px;">🎉</span>
  <h2 style="color:#00C896;margin:8px 0 4px;font-size:22px;">You just got your first tip!</h2>
  <p style="color:#7A9088;font-size:14px;margin:0;">Congratulations, {creator.display_name}</p>
</div>

<div style="background:#111A16;border:1px solid #1E2E26;border-radius:10px;padding:24px;margin-bottom:24px;text-align:center;">
  <p style="margin:0;font-size:12px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">First tip amount</p>
  <p style="margin:6px 0;font-size:40px;font-weight:800;color:#00C896;">{amount}</p>
  <p style="margin:0;font-size:14px;color:#E2E8F0;">from <strong>{tipper}</strong></p>
</div>

<p style="font-size:15px;line-height:1.7;color:#E2E8F0;margin:0 0 20px;">
  This is just the beginning. Keep sharing your tip page and engaging with your fans —
  every tip is a vote of confidence in your work.
</p>

{_btn("View your dashboard →", dashboard_url)}
"""

    html = _creator_email_wrapper(inner)
    body = (
        f"Congratulations {creator.display_name}! You received your first tip — "
        f"{amount} from {tipper}.\n\n"
        f"Dashboard: {dashboard_url}\n\n"
        f"— The TippingJar Team"
    )
    msg = EmailMultiAlternatives(
        subject=f"🎉 Your first tip — {amount} from {tipper}!",
        body=body,
        from_email=_no_reply(),
        to=[creator.user.email],
    )
    msg.attach_alternative(html, "text/html")
    try:
        msg.send(fail_silently=False)
        logger.info("send_first_tip_email: sent to %s for tip=%s", creator.user.email, tip.id)
    except Exception as exc:
        logger.error("send_first_tip_email: FAILED creator=%s error=%s", creator.id, exc)


def send_first_jar_email(creator, jar) -> None:
    """Email when a creator creates their first jar."""
    jar_url = f"{_BASE_URL}/creator/{creator.slug}"
    dashboard_url = f"{_BASE_URL}/dashboard"

    inner = f"""
<div style="text-align:center;margin-bottom:28px;">
  <span style="font-size:48px;">🫙</span>
  <h2 style="color:#00C896;margin:8px 0 4px;font-size:22px;">Your first jar is live!</h2>
  <p style="color:#7A9088;font-size:14px;margin:0;">{creator.display_name}</p>
</div>

<div style="background:#111A16;border:1px solid #1E2E26;border-radius:10px;padding:20px;margin-bottom:24px;">
  <p style="margin:0;font-size:12px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">Jar name</p>
  <p style="margin:4px 0 0;font-size:20px;font-weight:700;color:#E2E8F0;">{jar.name}</p>
  {f'<p style="margin:8px 0 0;font-size:13px;color:#7A9088;">{jar.description[:200]}</p>' if jar.description else ''}
  {f'<p style="margin:8px 0 0;font-size:14px;color:#00C896;font-weight:600;">Goal: R{jar.goal:.2f}</p>' if jar.goal else ''}
</div>

<p style="font-size:15px;line-height:1.7;color:#E2E8F0;margin:0 0 20px;">
  Tip jars let you collect towards specific goals. Share the link with your fans and
  watch the support roll in!
</p>

{_btn("Go to your page →", jar_url)}
"""

    html = _creator_email_wrapper(inner)
    body = (
        f"Hey {creator.display_name}! Your first jar '{jar.name}' is live.\n\n"
        f"Dashboard: {dashboard_url}\n\n"
        f"— The TippingJar Team"
    )
    msg = EmailMultiAlternatives(
        subject=f"🫙 Your first jar '{jar.name}' is live!",
        body=body,
        from_email=_no_reply(),
        to=[creator.user.email],
    )
    msg.attach_alternative(html, "text/html")
    try:
        msg.send(fail_silently=False)
        logger.info("send_first_jar_email: sent to %s", creator.user.email)
    except Exception as exc:
        logger.error("send_first_jar_email: FAILED creator=%s error=%s", creator.id, exc)


def send_first_thousand_email(creator) -> None:
    """Congratulations email when creator crosses R1 000 total."""
    dashboard_url = f"{_BASE_URL}/dashboard"

    inner = f"""
<div style="text-align:center;margin-bottom:28px;">
  <span style="font-size:48px;">💰</span>
  <h2 style="color:#00C896;margin:8px 0 4px;font-size:22px;">You've earned R1 000!</h2>
  <p style="color:#7A9088;font-size:14px;margin:0;">A massive milestone, {creator.display_name}</p>
</div>

<div style="background:linear-gradient(135deg,#0D1A12,#111A16);border:1px solid #00C896;border-radius:12px;padding:28px;margin-bottom:24px;text-align:center;">
  <p style="margin:0;font-size:13px;color:#7A9088;text-transform:uppercase;letter-spacing:1px;">Total tips earned</p>
  <p style="margin:8px 0;font-size:48px;font-weight:900;color:#00C896;letter-spacing:-1px;">R1 000+</p>
  <p style="margin:0;font-size:14px;color:#E2E8F0;">🏆 You're in the top tier of TippingJar creators</p>
</div>

<p style="font-size:15px;line-height:1.7;color:#E2E8F0;margin:0 0 20px;">
  R1 000 in tips is no small feat — it means your fans believe in what you're doing.
  Keep creating, keep sharing, and the support will keep growing!
</p>

{_btn("View your earnings →", dashboard_url)}
"""

    html = _creator_email_wrapper(inner)
    body = (
        f"Congratulations {creator.display_name}! You've crossed R1 000 in total tips. 🎉\n\n"
        f"Dashboard: {dashboard_url}\n\n"
        f"— The TippingJar Team"
    )
    msg = EmailMultiAlternatives(
        subject="💰 Congratulations! You've earned R1 000 on TippingJar!",
        body=body,
        from_email=_no_reply(),
        to=[creator.user.email],
    )
    msg.attach_alternative(html, "text/html")
    try:
        msg.send(fail_silently=False)
        logger.info("send_first_thousand_email: sent to %s", creator.user.email)
    except Exception as exc:
        logger.error("send_first_thousand_email: FAILED creator=%s error=%s", creator.id, exc)


def send_tipping_summary_email(creator, period_label: str, tips) -> None:
    """
    2-day tipping summary email.
    `tips` is a queryset/list of completed Tip objects in the period.
    """
    dashboard_url = f"{_BASE_URL}/dashboard"
    total = sum(float(t.amount) for t in tips)
    count = len(tips)

    tip_rows = "".join(
        f"""
<tr>
  <td style="padding:8px 0;font-size:13px;color:#E2E8F0;border-bottom:1px solid #1E2E26;">{t.tipper_name or "Anonymous"}</td>
  <td style="padding:8px 0;font-size:13px;color:#00C896;font-weight:600;text-align:right;border-bottom:1px solid #1E2E26;">R{float(t.amount):.2f}</td>
</tr>"""
        for t in tips[:10]  # cap at 10 rows in email
    )
    more_note = f'<p style="font-size:12px;color:#7A9088;margin:8px 0 0;">+{count - 10} more tips — view all in dashboard</p>' if count > 10 else ""

    inner = f"""
<h2 style="color:#00C896;margin:0 0 4px;font-size:20px;">Tips summary</h2>
<p style="color:#7A9088;margin:0 0 24px;font-size:13px;">{period_label}</p>

<div style="display:flex;gap:16px;margin-bottom:24px;">
  <div style="flex:1;background:#111A16;border:1px solid #1E2E26;border-radius:10px;padding:18px;text-align:center;">
    <p style="margin:0;font-size:12px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">Total earned</p>
    <p style="margin:4px 0 0;font-size:28px;font-weight:800;color:#00C896;">R{total:.2f}</p>
  </div>
  <div style="flex:1;background:#111A16;border:1px solid #1E2E26;border-radius:10px;padding:18px;text-align:center;">
    <p style="margin:0;font-size:12px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;">Tips received</p>
    <p style="margin:4px 0 0;font-size:28px;font-weight:800;color:#E2E8F0;">{count}</p>
  </div>
</div>

<table style="width:100%;border-collapse:collapse;margin-bottom:8px;">
  <thead>
    <tr>
      <th style="text-align:left;font-size:11px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;padding-bottom:8px;border-bottom:1px solid #1E2E26;">Tipper</th>
      <th style="text-align:right;font-size:11px;color:#7A9088;text-transform:uppercase;letter-spacing:.8px;padding-bottom:8px;border-bottom:1px solid #1E2E26;">Amount</th>
    </tr>
  </thead>
  <tbody>
    {tip_rows}
  </tbody>
</table>
{more_note}

{_btn("View full dashboard →", dashboard_url)}
"""

    html = _creator_email_wrapper(inner)
    body = (
        f"TippingJar tips summary for {creator.display_name} — {period_label}\n\n"
        f"Total: R{total:.2f} across {count} tip{'s' if count != 1 else ''}.\n\n"
        f"Dashboard: {dashboard_url}\n\n"
        f"— The TippingJar Team"
    )
    msg = EmailMultiAlternatives(
        subject=f"Your TippingJar summary — R{total:.2f} in {count} tip{'s' if count != 1 else ''}",
        body=body,
        from_email=_no_reply(),
        to=[creator.user.email],
    )
    msg.attach_alternative(html, "text/html")
    try:
        msg.send(fail_silently=False)
        logger.info("send_tipping_summary_email: sent to %s", creator.user.email)
    except Exception as exc:
        logger.error("send_tipping_summary_email: FAILED creator=%s error=%s", creator.id, exc)


def send_dispute_status_update(dispute):
    """Notify disputer when admin updates the dispute status."""
    url = dispute.tracking_url
    ref = dispute.reference
    status_label = dispute.get_status_display()

    body = (
        f"Hi {dispute.name},\n\n"
        f"Your dispute {ref} has been updated.\n\n"
        f"New status: {status_label}\n\n"
        f"{'Notes: ' + dispute.admin_notes + chr(10) + chr(10) if dispute.admin_notes else ''}"
        f"View full details:\n  {url}\n\n"
        f"— TippingJar Support"
    )
    html = f"""
<div style="font-family:Inter,sans-serif;max-width:560px;margin:auto;padding:32px;background:#0A0F0D;color:#E2E8F0;border-radius:12px;">
  <h2 style="color:#00C896;margin-bottom:4px;">Dispute update — {ref}</h2>
  <p style="font-size:15px;">Hi {dispute.name}, your dispute status has changed to
    <strong style="color:#00C896;">{status_label}</strong>.
  </p>
  {'<div style="background:#111A16;border:1px solid #1E2E26;border-radius:8px;padding:16px;margin:16px 0;"><p style="margin:0;font-size:13px;color:#7A9088;">Notes from our team</p><p style="margin:6px 0 0;font-size:14px;">' + dispute.admin_notes + '</p></div>' if dispute.admin_notes else ''}
  <a href="{url}" style="display:inline-block;background:#00C896;color:#fff;text-decoration:none;padding:12px 28px;border-radius:36px;font-weight:700;font-size:14px;margin:8px 0;">
    View dispute →
  </a>
</div>"""

    msg = EmailMultiAlternatives(
        subject=f"Dispute {ref} updated — {status_label}",
        body=body,
        from_email=_no_reply(),
        to=[dispute.email],
        reply_to=[_support()],
    )
    msg.attach_alternative(html, "text/html")
    msg.send(fail_silently=True)
