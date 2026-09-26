import random
import string
from datetime import timedelta

from django.db import models
from django.utils import timezone


def _gen_code():
    """Random 8-character alphanumeric referral code, e.g. 'JANE4F2A'."""
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=8))


class ReferralCode(models.Model):
    """
    One referral code per user.  Admin can adjust the commission_rate per code.
    Default rate: 1 % (0.01).
    """

    owner = models.OneToOneField(
        "users.User", on_delete=models.CASCADE, related_name="referral_code_obj"
    )
    code = models.CharField(max_length=20, unique=True, default=_gen_code)
    commission_rate = models.DecimalField(
        max_digits=5,
        decimal_places=4,
        default=0.0100,
        help_text="Fraction of tips earned by referred creator paid to referrer. 0.01 = 1 %.",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.code} ({self.owner.email}) @ {float(self.commission_rate) * 100:.1f}%"


class Referral(models.Model):
    """
    Created when a new user signs up with a valid referral code.
    Tracks the 6-month commission window and the referrer's bank details.
    """

    class Status(models.TextChoices):
        PENDING = "pending", "Pending Bank Details"
        ACTIVE = "active", "Active"
        EXPIRED = "expired", "Expired"

    referrer = models.ForeignKey(
        "users.User", on_delete=models.CASCADE, related_name="referrals_made"
    )
    referred_user = models.OneToOneField(
        "users.User", on_delete=models.CASCADE, related_name="referral_record"
    )
    referral_code = models.ForeignKey(
        ReferralCode,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="referrals",
    )
    # Locked-in at signup — admin changes to the code do not retroactively change this
    commission_rate = models.DecimalField(max_digits=5, decimal_places=4)
    commission_months = models.PositiveSmallIntegerField(default=6)
    expires_at = models.DateTimeField()
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING
    )

    # Bank details for commission payout (submitted by referrer after notification)
    bank_name = models.CharField(max_length=100, blank=True)
    bank_account_name = models.CharField(max_length=150, blank=True)
    bank_account_number = models.CharField(max_length=30, blank=True)
    bank_details_submitted_at = models.DateTimeField(null=True, blank=True)

    signed_up_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-signed_up_at"]

    def __str__(self):
        return f"{self.referrer.email} → {self.referred_user.email}"

    def save(self, *args, **kwargs):
        if not self.pk and not self.expires_at:
            self.expires_at = timezone.now() + timedelta(
                days=30 * self.commission_months
            )
        super().save(*args, **kwargs)

    @property
    def is_within_window(self) -> bool:
        return timezone.now() < self.expires_at

    @property
    def days_remaining(self) -> int:
        delta = self.expires_at - timezone.now()
        return max(0, delta.days)
