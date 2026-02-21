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
