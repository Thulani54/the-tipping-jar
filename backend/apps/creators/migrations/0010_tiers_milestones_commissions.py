import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("creators", "0009_creatorprofile_onboarding_fields"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="SupportTier",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=100)),
                ("price", models.DecimalField(decimal_places=2, max_digits=10)),
                ("description", models.TextField(blank=True)),
                ("perks", models.JSONField(default=list)),
                ("is_active", models.BooleanField(default=True)),
                ("sort_order", models.PositiveSmallIntegerField(default=0)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("creator", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="support_tiers",
                    to="creators.creatorprofile",
                )),
            ],
            options={"ordering": ["price"]},
        ),
        migrations.CreateModel(
            name="MilestoneGoal",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("target_amount", models.DecimalField(decimal_places=2, max_digits=10)),
                ("title", models.CharField(max_length=200)),
                ("description", models.TextField(blank=True)),
                ("is_active", models.BooleanField(default=True)),
                ("is_achieved", models.BooleanField(default=False)),
                ("achieved_at", models.DateTimeField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("creator", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="milestones",
                    to="creators.creatorprofile",
                )),
                ("bonus_post", models.ForeignKey(
                    blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    to="creators.creatorpost",
                )),
            ],
            options={"ordering": ["target_amount"]},
        ),
        migrations.CreateModel(
            name="CommissionSlot",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("is_open", models.BooleanField(default=False)),
                ("base_price", models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ("description", models.TextField(blank=True)),
                ("turnaround_days", models.PositiveSmallIntegerField(default=7)),
                ("max_active_requests", models.PositiveSmallIntegerField(default=5)),
                ("creator", models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="commission_slot",
                    to="creators.creatorprofile",
                )),
            ],
        ),
        migrations.CreateModel(
            name="CommissionRequest",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("fan_name", models.CharField(max_length=100)),
                ("fan_email", models.EmailField(max_length=254)),
                ("title", models.CharField(max_length=200)),
                ("description", models.TextField()),
                ("agreed_price", models.DecimalField(decimal_places=2, max_digits=10)),
                ("status", models.CharField(
                    choices=[
                        ("pending", "Pending"), ("accepted", "Accepted"),
                        ("declined", "Declined"), ("completed", "Completed"),
                    ],
                    default="pending", max_length=10,
                )),
                ("delivery_note", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("creator", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="commission_requests",
                    to="creators.creatorprofile",
                )),
                ("fan", models.ForeignKey(
                    blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={"ordering": ["-created_at"]},
        ),
    ]
