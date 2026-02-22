from django.conf import settings
from django.db import models


class Tip(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        COMPLETED = "completed", "Completed"
        FAILED = "failed", "Failed"
        REFUNDED = "refunded", "Refunded"

    creator = models.ForeignKey(
        "creators.CreatorProfile",
        on_delete=models.CASCADE,
        related_name="tips",
    )
    tipper = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="tips_sent",
    )
    tipper_name = models.CharField(max_length=100, blank=True, default="Anonymous")
    tipper_email = models.EmailField(blank=True, default="")
    amount = models.DecimalField(max_digits=8, decimal_places=2)
    message = models.TextField(blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    jar = models.ForeignKey(
        "creators.Jar",
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="jar_tips",
    )
    stripe_payment_intent_id = models.CharField(max_length=200, blank=True)  # legacy
    paystack_reference = models.CharField(max_length=200, blank=True, db_index=True)
    paystack_authorization_code = models.CharField(max_length=200, blank=True)
    # Fee snapshot at the time of the tip
    platform_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    service_fee  = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    creator_net  = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.tipper_name} → {self.creator} (R{self.amount})"


class Pledge(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        PAUSED = "paused", "Paused"
        CANCELLED = "cancelled", "Cancelled"

    fan = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="pledges",
    )
    fan_email = models.EmailField(blank=True)
    fan_name = models.CharField(max_length=100, default="Anonymous")
    creator = models.ForeignKey(
        "creators.CreatorProfile",
        on_delete=models.CASCADE,
        related_name="pledges",
    )
    tier = models.ForeignKey(
        "creators.SupportTier",
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="pledges",
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE)
    paystack_authorization_code = models.CharField(max_length=200, blank=True)
    paystack_email = models.EmailField(blank=True)
    next_charge_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = [("fan", "creator")]

    def __str__(self):
        return f"{self.fan_name} → {self.creator} pledge R{self.amount}/mo"


class TipStreak(models.Model):
    fan = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="tip_streaks",
    )
    fan_email = models.EmailField(blank=True, db_index=True)
    creator = models.ForeignKey(
        "creators.CreatorProfile",
        on_delete=models.CASCADE,
        related_name="tip_streaks",
    )
    current_streak = models.PositiveIntegerField(default=1)
    max_streak = models.PositiveIntegerField(default=1)
    last_tip_month = models.DateField()
    badges = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [("fan", "creator"), ("fan_email", "creator")]

    def __str__(self):
        return f"{self.fan_email} streak {self.current_streak}mo → {self.creator}"
