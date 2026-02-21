"""
Email helpers for the support app.

All outbound mail uses accounts@ for SMTP auth (configured in settings).
Dispute / contact confirmations set the From header to no-reply@.
Support notifications land in support@.
"""
from django.conf import settings
from django.core.mail import EmailMultiAlternatives


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

def send_tip_thank_you(tip):
    """Send a thank-you email to the tipper after a successful payment."""
    if not tip.tipper_email:
        return

    creator = tip.creator
    tipper_name = tip.tipper_name or "there"
    amount = f"R{tip.amount:.2f}"
    jar_name = tip.jar.name if tip.jar else None
    creator_page = f"https://www.tippingjar.co.za/creator/{creator.slug}"

    custom_msg = (creator.thank_you_message.strip()
                  if creator.thank_you_message.strip()
                  else f"Thank you so much for the support — it truly means the world to me!")

    subject = f"{creator.display_name} thanks you for your tip 💚"

    jar_line = f" into the <strong>{jar_name}</strong> jar" if jar_name else ""
    jar_line_text = f" into the '{jar_name}' jar" if jar_name else ""

    body = (
        f"Hi {tipper_name},\n\n"
        f"You sent a {amount} tip{jar_line_text} to {creator.display_name}.\n\n"
        f"{custom_msg}\n\n"
        f"Visit {creator.display_name}'s page: {creator_page}\n\n"
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
  <a href="{creator_page}" style="display:block;text-align:center;background:#00C896;color:#fff;text-decoration:none;padding:14px 28px;border-radius:36px;font-weight:700;font-size:15px;margin-bottom:24px;">
    Visit {creator.display_name}'s page →
  </a>
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
    msg.send(fail_silently=True)


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
