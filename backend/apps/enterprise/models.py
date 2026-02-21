from django.conf import settings
from django.db import models


class Enterprise(models.Model):
    """An enterprise / agency account that manages multiple creator profiles."""

    class Plan(models.TextChoices):
        GROWTH = "growth", "Growth"
        SCALE = "scale", "Scale"
        CUSTOM = "custom", "Custom"

    admin = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="enterprise",
    )
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    logo = models.ImageField(upload_to="enterprise_logos/", null=True, blank=True)
    website = models.URLField(blank=True)
    plan = models.CharField(max_length=10, choices=Plan.choices, default=Plan.GROWTH)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.plan})"

    @property
    def creator_count(self):
        return self.memberships.filter(is_active=True).count()


class EnterpriseMembership(models.Model):
    """
    Links a CreatorProfile to an Enterprise.
    An enterprise admin can add/remove creators; creators can be in
    multiple enterprises (though uncommon).
    """

    enterprise = models.ForeignKey(
        Enterprise, on_delete=models.CASCADE, related_name="memberships"
    )
    creator = models.ForeignKey(
        "creators.CreatorProfile",
        on_delete=models.CASCADE,
        related_name="enterprise_memberships",
    )
    joined_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = [("enterprise", "creator")]
        ordering = ["-joined_at"]

    def __str__(self):
        return f"{self.enterprise.name} → {self.creator.display_name}"


class FundDistribution(models.Model):
    """
    A batch of fund distributions recorded by an enterprise admin.
    Represents money allocated across multiple managed creators.
    """

    enterprise = models.ForeignKey(
        Enterprise, on_delete=models.CASCADE, related_name="distributions"
    )
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    notes = models.TextField(blank=True)
    distributed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="distributions_made",
    )
    distributed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-distributed_at"]

    def __str__(self):
        return f"{self.enterprise.name} — R{self.total_amount} on {self.distributed_at:%Y-%m-%d}"

    @property
    def reference(self):
        return f"DIST-{self.pk:05d}"


class FundDistributionItem(models.Model):
    """A single line in a FundDistribution — amount allocated to one creator."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        PAID = "paid", "Paid"
        FAILED = "failed", "Failed"

    distribution = models.ForeignKey(
        FundDistribution, on_delete=models.CASCADE, related_name="items"
    )
    creator = models.ForeignKey(
        "creators.CreatorProfile",
        on_delete=models.CASCADE,
        related_name="distribution_items",
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    reference = models.CharField(max_length=100, blank=True, help_text="Bank ref / EFT ref")
    paid_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-distribution__distributed_at"]

    def __str__(self):
        return f"{self.distribution.reference} → {self.creator.display_name}: R{self.amount}"
