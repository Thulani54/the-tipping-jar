import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="BlogPost",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("title", models.CharField(max_length=255)),
                (
                    "slug",
                    models.SlugField(blank=True, max_length=255, unique=True),
                ),
                (
                    "category",
                    models.CharField(
                        choices=[
                            ("creator-guide", "Creator Guide"),
                            ("product", "Product"),
                            ("industry", "Industry"),
                            ("company", "Company"),
                            ("tips-tricks", "Tips & Tricks"),
                        ],
                        default="creator-guide",
                        max_length=30,
                    ),
                ),
                (
                    "excerpt",
                    models.TextField(
                        help_text="Short summary shown on the blog listing page (1–2 sentences)."
                    ),
                ),
                (
                    "content",
                    models.TextField(
                        help_text="Full rich-text body. Supports HTML from the editor."
                    ),
                ),
                (
                    "cover_image",
                    models.ImageField(
                        blank=True,
                        help_text="Optional cover image shown at the top of the post.",
                        null=True,
                        upload_to="blog/covers/",
                    ),
                ),
                (
                    "author_name",
                    models.CharField(default="TippingJar Team", max_length=120),
                ),
                (
                    "read_time",
                    models.CharField(
                        default="5 min read",
                        help_text='Displayed read time, e.g. "5 min read".',
                        max_length=20,
                    ),
                ),
                ("is_published", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={
                "verbose_name": "Blog Post",
                "verbose_name_plural": "Blog Posts",
                "ordering": ["-created_at"],
            },
        ),
    ]
