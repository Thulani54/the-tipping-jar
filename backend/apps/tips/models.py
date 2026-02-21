from django.db import models
from django.conf import settings


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
    # Fee snapshot at the time of the tip
    platform_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    service_fee  = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    creator_net  = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.tipper_name} → {self.creator} (R{self.amount})"
