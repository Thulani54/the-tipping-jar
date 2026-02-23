from django.conf import settings
from django.db import models


class CreatorProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="creator_profile",
    )
    display_name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    tagline = models.CharField(max_length=200, blank=True)
    cover_image = models.ImageField(upload_to="covers/", null=True, blank=True)
    tip_goal = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True,
        help_text="Monthly tip goal in ZAR (Rands)"
    )
    stripe_account_id = models.CharField(max_length=100, blank=True)   # legacy
    paystack_subaccount_code = models.CharField(
        max_length=100, blank=True,
        help_text="Paystack subaccount code (ACCT_xxxx) — auto-created on bank detail save",
    )
    paystack_subaccount_id = models.CharField(max_length=100, blank=True)
    thank_you_message = models.TextField(
        blank=True, default="",
        help_text="Custom thank-you note sent to tippers after a successful payment.",
    )
    category = models.CharField(max_length=50, blank=True, default="")
    platforms = models.CharField(max_length=200, blank=True, default="")  # comma-separated
    audience_size = models.CharField(max_length=50, blank=True, default="")
    age_group = models.CharField(max_length=50, blank=True, default="")
    audience_gender = models.CharField(max_length=30, blank=True, default="")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # ── Banking details ───────────────────────────────────────────────
    bank_name = models.CharField(max_length=100, blank=True)
    bank_account_holder = models.CharField(max_length=200, blank=True)
    bank_account_number = models.CharField(max_length=50, blank=True)   # store encrypted in prod
    bank_routing_number = models.CharField(max_length=50, blank=True)   # routing / sort / BSB
    ACCOUNT_TYPE_CHOICES = [('checking', 'Checking'), ('savings', 'Savings')]
    bank_account_type = models.CharField(
        max_length=20, choices=ACCOUNT_TYPE_CHOICES, blank=True, default='checking'
    )
    bank_country = models.CharField(max_length=2, blank=True, default='US')

    def __str__(self):
        return self.display_name

    @property
    def total_tips(self):
        return self.tips.filter(status="completed").aggregate(
            total=models.Sum("amount")
        )["total"] or 0


class CreatorPost(models.Model):
    class PostType(models.TextChoices):
        TEXT  = "text",  "Text"
        IMAGE = "image", "Image"
        VIDEO = "video", "Video"
        FILE  = "file",  "File"

    creator      = models.ForeignKey(CreatorProfile, on_delete=models.CASCADE, related_name="posts")
    title        = models.CharField(max_length=200)
    body         = models.TextField(blank=True, default="")
    media_file   = models.FileField(upload_to="posts/", blank=True, null=True)
    video_url    = models.URLField(blank=True, default="")
    post_type    = models.CharField(max_length=10, choices=PostType.choices, default=PostType.TEXT)
    is_published = models.BooleanField(default=True)
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.creator.display_name} — {self.title}"


class SupportTier(models.Model):
    creator = models.ForeignKey(
        "CreatorProfile", on_delete=models.CASCADE, related_name="support_tiers"
    )
    name = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.TextField(blank=True)
    perks = models.JSONField(default=list)
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["price"]

    def __str__(self):
        return f"{self.creator.display_name} — {self.name} (R{self.price}/mo)"


class MilestoneGoal(models.Model):
    creator = models.ForeignKey(
        "CreatorProfile", on_delete=models.CASCADE, related_name="milestones"
    )
    target_amount = models.DecimalField(max_digits=10, decimal_places=2)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    bonus_post = models.ForeignKey(
        "CreatorPost", on_delete=models.SET_NULL, null=True, blank=True
    )
    is_active = models.BooleanField(default=True)
    is_achieved = models.BooleanField(default=False)
    achieved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["target_amount"]

    def __str__(self):
        return f"{self.creator.display_name} — {self.title} (R{self.target_amount})"


class CommissionSlot(models.Model):
    creator = models.OneToOneField(
        "CreatorProfile", on_delete=models.CASCADE, related_name="commission_slot"
    )
    is_open = models.BooleanField(default=False)
    base_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    description = models.TextField(blank=True)
    turnaround_days = models.PositiveSmallIntegerField(default=7)
    max_active_requests = models.PositiveSmallIntegerField(default=5)

    def __str__(self):
        status = "open" if self.is_open else "closed"
        return f"{self.creator.display_name} commissions ({status})"


class CommissionRequest(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACCEPTED = "accepted", "Accepted"
        DECLINED = "declined", "Declined"
        COMPLETED = "completed", "Completed"

    creator = models.ForeignKey(
        "CreatorProfile", on_delete=models.CASCADE, related_name="commission_requests"
    )
    fan = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL, null=True, blank=True,
    )
    fan_name = models.CharField(max_length=100)
    fan_email = models.EmailField()
    title = models.CharField(max_length=200)
    description = models.TextField()
    agreed_price = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING
    )
    delivery_note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.fan_name} → {self.creator.display_name}: {self.title}"


class Jar(models.Model):
    """A named campaign / purpose a creator can collect tips into."""

    creator = models.ForeignKey(
        CreatorProfile, on_delete=models.CASCADE, related_name="jars"
    )
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=100)
    description = models.TextField(blank=True)
    goal = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True,
        help_text="Optional fundraising goal in ZAR (Rands)",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = [("creator", "slug")]

    def __str__(self):
        return f"{self.creator.display_name} — {self.name}"

    @property
    def total_raised(self):
        return self.jar_tips.filter(status="completed").aggregate(
            total=models.Sum("amount")
        )["total"] or 0

    @property
    def tip_count(self):
        return self.jar_tips.filter(status="completed").count()
