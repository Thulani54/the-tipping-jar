import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="Platform",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False, verbose_name="ID"
                    ),
                ),
                ("name", models.CharField(max_length=200)),
                ("slug", models.SlugField(unique=True)),
                ("website", models.URLField(blank=True)),
                ("description", models.TextField(blank=True)),
                ("intended_use", models.TextField(blank=True)),
                ("company_name_legal", models.CharField(blank=True, max_length=200)),
                ("company_registration_number", models.CharField(blank=True, max_length=100)),
                ("vat_number", models.CharField(blank=True, max_length=50)),
                ("contact_name", models.CharField(blank=True, max_length=100)),
                ("contact_email", models.EmailField(blank=True, max_length=254)),
                ("contact_phone", models.CharField(blank=True, max_length=20)),
                (
                    "approval_status",
                    models.CharField(
                        choices=[
                            ("pending", "Pending"),
                            ("approved", "Approved"),
                            ("rejected", "Rejected"),
                            ("suspended", "Suspended"),
                        ],
                        default="pending",
                        max_length=10,
                    ),
                ),
                ("rejection_reason", models.TextField(blank=True)),
                ("platform_key_hash", models.CharField(blank=True, max_length=64, unique=True)),
                ("platform_key_prefix", models.CharField(blank=True, max_length=50)),
                ("is_active", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "owner",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="owned_platforms",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "ordering": ["-created_at"],
            },
        ),
        migrations.CreateModel(
            name="PlatformDocument",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False, verbose_name="ID"
                    ),
                ),
                (
                    "doc_type",
                    models.CharField(
                        choices=[
                            ("cipc", "Company Registration (CIPC)"),
                            ("vat", "VAT Certificate"),
                            ("id", "Director ID / Passport"),
                            ("bank", "Bank Confirmation Letter"),
                        ],
                        max_length=10,
                    ),
                ),
                ("file", models.FileField(upload_to="platform_docs/%Y/")),
                ("uploaded_at", models.DateTimeField(auto_now_add=True)),
                (
                    "platform",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="documents",
                        to="platform.platform",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="PlatformUser",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False, verbose_name="ID"
                    ),
                ),
                (
                    "external_id",
                    models.CharField(
                        blank=True,
                        help_text="ID from third-party system",
                        max_length=200,
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "platform",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="platform_users",
                        to="platform.platform",
                    ),
                ),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="platform_memberships",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "ordering": ["-created_at"],
                "unique_together": {("platform", "user")},
            },
        ),
    ]
