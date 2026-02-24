from django.db import models
from django.utils.text import slugify


class BlogCategory(models.TextChoices):
    CREATOR_GUIDE = "creator-guide", "Creator Guide"
    PRODUCT = "product", "Product"
    INDUSTRY = "industry", "Industry"
    COMPANY = "company", "Company"
    TIPS_TRICKS = "tips-tricks", "Tips & Tricks"


class BlogPost(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, blank=True)
    category = models.CharField(
        max_length=30, choices=BlogCategory.choices, default=BlogCategory.CREATOR_GUIDE
    )
    excerpt = models.TextField(
        help_text="Short summary shown on the blog listing page (1–2 sentences)."
    )
    content = models.TextField(
        help_text="Full rich-text body. Supports HTML from the editor."
    )
    cover_image = models.ImageField(
        upload_to="blog/covers/", null=True, blank=True,
        help_text="Optional cover image shown at the top of the post."
    )
    author_name = models.CharField(max_length=120, default="TippingJar Team")
    read_time = models.CharField(
        max_length=20, default="5 min read",
        help_text='Displayed read time, e.g. "5 min read".'
    )
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Blog Post"
        verbose_name_plural = "Blog Posts"

    def save(self, *args, **kwargs):
        if not self.slug:
            base = slugify(self.title)
            slug = base
            n = 1
            while BlogPost.objects.filter(slug=slug).exclude(pk=self.pk).exists():
                slug = f"{base}-{n}"
                n += 1
            self.slug = slug
        super().save(*args, **kwargs)

    def __str__(self):
        return self.title
