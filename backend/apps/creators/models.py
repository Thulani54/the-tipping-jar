from django.db import models
from django.conf import settings


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
        help_text="Monthly tip goal in USD"
    )
    stripe_account_id = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.display_name

    @property
    def total_tips(self):
        return self.tips.filter(status="completed").aggregate(
            total=models.Sum("amount")
        )["total"] or 0
