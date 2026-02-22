import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("creators", "0010_tiers_milestones_commissions"),
        ("tips", "0006_tip_paystack_authorization_code"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="Pledge",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("fan_email", models.EmailField(blank=True, max_length=254)),
                ("fan_name", models.CharField(default="Anonymous", max_length=100)),
                ("amount", models.DecimalField(decimal_places=2, max_digits=10)),
                ("status", models.CharField(
                    choices=[("active", "Active"), ("paused", "Paused"), ("cancelled", "Cancelled")],
                    default="active", max_length=10,
                )),
                ("paystack_authorization_code", models.CharField(blank=True, max_length=200)),
                ("paystack_email", models.EmailField(blank=True, max_length=254)),
                ("next_charge_date", models.DateField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("creator", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="pledges",
                    to="creators.creatorprofile",
                )),
                ("fan", models.ForeignKey(
                    blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name="pledges",
                    to=settings.AUTH_USER_MODEL,
                )),
                ("tier", models.ForeignKey(
                    blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name="pledges",
                    to="creators.supporttier",
                )),
            ],
            options={"ordering": ["-created_at"]},
        ),
        migrations.AddConstraint(
            model_name="pledge",
            constraint=models.UniqueConstraint(
                condition=models.Q(fan__isnull=False),
                fields=["fan", "creator"],
                name="unique_fan_creator_pledge",
            ),
        ),
        migrations.CreateModel(
            name="TipStreak",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("fan_email", models.EmailField(blank=True, db_index=True, max_length=254)),
                ("current_streak", models.PositiveIntegerField(default=1)),
                ("max_streak", models.PositiveIntegerField(default=1)),
                ("last_tip_month", models.DateField()),
                ("badges", models.JSONField(default=list)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("creator", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="tip_streaks",
                    to="creators.creatorprofile",
                )),
                ("fan", models.ForeignKey(
                    blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name="tip_streaks",
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
        ),
        migrations.AddConstraint(
            model_name="tipstreak",
            constraint=models.UniqueConstraint(
                condition=models.Q(fan__isnull=False),
                fields=["fan", "creator"],
                name="unique_fan_creator_streak",
            ),
        ),
        migrations.AddConstraint(
            model_name="tipstreak",
            constraint=models.UniqueConstraint(
                condition=models.Q(fan_email__gt=""),
                fields=["fan_email", "creator"],
                name="unique_fan_email_creator_streak",
            ),
        ),
    ]
