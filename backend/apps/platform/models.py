import hashlib
import secrets

from django.conf import settings
from django.db import models


class Platform(models.Model):
    """A third-party application that embeds TippingJar tipping via the Platform API."""

    class ApprovalStatus(models.TextChoices):
        PENDING   = "pending",   "Pending"
        APPROVED  = "approved",  "Approved"
        REJECTED  = "rejected",  "Rejected"
        SUSPENDED = "suspended", "Suspended"

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="owned_platforms",
    )
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    website = models.URLField(blank=True)
    description = models.TextField(blank=True)
    intended_use = models.TextField(blank=True)

    # ── Company info ───────────────────────────────────────────────────────────
    company_name_legal = models.CharField(max_length=200, blank=True)
    company_registration_number = models.CharField(max_length=100, blank=True)
    vat_number = models.CharField(max_length=50, blank=True)
    contact_name = models.CharField(max_length=100, blank=True)
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)

    # ── Approval ───────────────────────────────────────────────────────────────
    approval_status = models.CharField(
        max_length=10, choices=ApprovalStatus.choices, default=ApprovalStatus.PENDING
    )
    rejection_reason = models.TextField(blank=True)

    # ── API key (SHA-256 of raw key stored; raw shown once) ────────────────────
    platform_key_hash = models.CharField(max_length=64, unique=True, blank=True)
    platform_key_prefix = models.CharField(max_length=50, blank=True)

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name} ({self.approval_status})"

    @staticmethod
    def generate_key():
        """
        Returns (raw_key, key_hash, key_prefix).
        Store hash + prefix; show raw_key once.
        """
        raw = f"tj_platform_sk_v1_{secrets.token_hex(16)}"
        key_hash = hashlib.sha256(raw.encode()).hexdigest()
        prefix = raw[:30] + "..."
        return raw, key_hash, prefix


class PlatformDocument(models.Model):
    """A compliance document uploaded for platform approval."""

    class DocType(models.TextChoices):
        CIPC = "cipc", "Company Registration (CIPC)"
        VAT  = "vat",  "VAT Certificate"
        ID   = "id",   "Director ID / Passport"
        BANK = "bank", "Bank Confirmation Letter"

    platform = models.ForeignKey(
        Platform, on_delete=models.CASCADE, related_name="documents"
    )
    doc_type = models.CharField(max_length=10, choices=DocType.choices)
    file = models.FileField(upload_to="platform_docs/%Y/")
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.platform.name} — {self.get_doc_type_display()}"


class PlatformUser(models.Model):
    """Maps a TippingJar User to a Platform (end-user scoping)."""

    platform = models.ForeignKey(
        Platform, on_delete=models.CASCADE, related_name="platform_users"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="platform_memberships",
    )
    external_id = models.CharField(max_length=200, blank=True, help_text="ID from third-party system")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("platform", "user")]
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.platform.name} → {self.user.email}"
