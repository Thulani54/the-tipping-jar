import hashlib
import random
import secrets
from datetime import timedelta

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    """Extended user model — can be a fan, a creator, or both."""

    class Role(models.TextChoices):
        FAN = "fan", "Fan"
        CREATOR = "creator", "Creator"
        ENTERPRISE = "enterprise", "Enterprise"
        ADMIN = "admin", "Admin"

    class OtpMethod(models.TextChoices):
        EMAIL = "email", "Email"
        SMS = "sms", "SMS"

    email = models.EmailField(unique=True)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.FAN)

    @property
    def is_enterprise(self) -> bool:
        return self.role == self.Role.ENTERPRISE

    @property
    def is_admin(self) -> bool:
        return self.role == self.Role.ADMIN
    avatar = models.ImageField(upload_to="avatars/", null=True, blank=True)
    bio = models.TextField(blank=True)
    phone_number = models.CharField(
        max_length=20, blank=True,
        help_text="International format, e.g. +27821234567. Required for SMS OTP.",
    )
    otp_method = models.CharField(
        max_length=5, choices=OtpMethod.choices, default=OtpMethod.EMAIL,
        help_text="Preferred OTP delivery channel.",
    )
    two_fa_enabled = models.BooleanField(
        default=False,
        help_text="When False, login skips the OTP step entirely.",
    )

    class Gender(models.TextChoices):
        MALE = "male", "Male"
        FEMALE = "female", "Female"
        NON_BINARY = "non_binary", "Non-binary"
        PREFER_NOT = "prefer_not_to_say", "Prefer not to say"

    gender = models.CharField(
        max_length=20, choices=Gender.choices, blank=True, default="",
        help_text="User's gender identity.",
    )
    date_of_birth = models.DateField(
        null=True, blank=True,
        help_text="User's date of birth (YYYY-MM-DD).",
    )

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return self.email


class OTP(models.Model):
    """One-time password for email or SMS verification."""

    class Method(models.TextChoices):
        EMAIL = "email", "Email"
        SMS = "sms", "SMS"

    user = models.ForeignKey(
        "users.User", on_delete=models.CASCADE, related_name="otps"
    )
    code = models.CharField(max_length=6)
    method = models.CharField(max_length=5, choices=Method.choices, default=Method.EMAIL)
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"OTP({self.user.email}, {self.method}, used={self.is_used})"

    def is_valid(self) -> bool:
        return not self.is_used and timezone.now() < self.expires_at

    @classmethod
    def generate_for(cls, user: "User", method: str = "email", ttl_minutes: int = 10) -> tuple["OTP", str]:
        """
        Create a new OTP for *user*, invalidating all previous unused ones.
        Returns (otp_instance, raw_code).
        """
        cls.objects.filter(user=user, is_used=False).update(is_used=True)
        raw_code = f"{random.randint(0, 999999):06d}"
        otp = cls.objects.create(
            user=user,
            code=raw_code,
            method=method,
            expires_at=timezone.now() + timedelta(minutes=ttl_minutes),
        )
        return otp, raw_code


class ApiKey(models.Model):
    """
    Permanent API credential tied to a user account.

    The full raw key (tj_live_sk_v1_<hex32>) is returned ONCE at creation
    and never stored — only its SHA-256 hash is persisted.
    """

    user = models.ForeignKey(
        "users.User", on_delete=models.CASCADE, related_name="api_keys"
    )
    name = models.CharField(max_length=100, default="My Key")
    # SHA-256 hex digest of the raw key
    key_hash = models.CharField(max_length=64, unique=True)
    # Safe display string shown in the UI, e.g. "tj_live_sk_v1_ab3f1c2d..."
    prefix = models.CharField(max_length=40)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} — {self.name} ({self.prefix})"

    @staticmethod
    def generate():
        """Return (raw_key, key_hash, display_prefix) — call once, store the hash."""
        raw = f"tj_live_sk_v1_{secrets.token_hex(16)}"
        hashed = hashlib.sha256(raw.encode()).hexdigest()
        prefix = raw[:26] + "..."
        return raw, hashed, prefix

    @staticmethod
    def hash_key(raw_key: str) -> str:
        return hashlib.sha256(raw_key.encode()).hexdigest()
