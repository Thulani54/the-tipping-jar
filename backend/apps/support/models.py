import uuid

from django.conf import settings
from django.db import models


class ContactMessage(models.Model):
    """Inbound contact form submission — forwarded to support@tippingjar.co.za."""

    class Subject(models.TextChoices):
        GENERAL      = "general",      "General Enquiry"
        TECHNICAL    = "technical",    "Technical Issue"
        BILLING      = "billing",      "Billing / Payments"
        PARTNERSHIP  = "partnership",  "Partnership"
        OTHER        = "other",        "Other"

    name       = models.CharField(max_length=100)
    email      = models.EmailField()
    subject    = models.CharField(max_length=30, choices=Subject.choices, default=Subject.GENERAL)
    message    = models.TextField()
    is_resolved = models.BooleanField(default=False)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name} — {self.get_subject_display()}"


class Dispute(models.Model):
    """A formal dispute raised by a user or anonymous tipper."""

    class Status(models.TextChoices):
        OPEN          = "open",          "Open"
        INVESTIGATING = "investigating", "Under Investigation"
        RESOLVED      = "resolved",      "Resolved"
        CLOSED        = "closed",        "Closed"

    class Reason(models.TextChoices):
        TIP_NOT_RECEIVED = "tip_not_received", "Tip Not Received by Creator"
        WRONG_AMOUNT     = "wrong_amount",      "Wrong Amount Charged"
        UNAUTHORIZED     = "unauthorized",      "Unauthorized Transaction"
        PAYOUT_ISSUE     = "payout_issue",      "Payout / Withdrawal Issue"
        ACCOUNT_ACCESS   = "account_access",    "Account Access Problem"
        OTHER            = "other",             "Other"

    # Submitter
    user  = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name="disputes",
    )
    name  = models.CharField(max_length=100)
    email = models.EmailField()

    # Dispute details
    reason      = models.CharField(max_length=30, choices=Reason.choices)
    description = models.TextField()
    tip_ref     = models.CharField(max_length=50, blank=True,
                                   help_text="Optional tip ID / payment reference")

    # Status
    status      = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)
    admin_notes = models.TextField(blank=True)

    # Unique token used in the email tracking link
    token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Dispute #{self.pk} — {self.get_reason_display()} [{self.status}]"

    @property
    def reference(self):
        return f"TJ-DISP-{self.pk:05d}"

    @property
    def tracking_url(self):
        site = getattr(settings, "SITE_URL", "https://tippingjar.co.za")
        return f"{site}/dispute/{self.token}"
