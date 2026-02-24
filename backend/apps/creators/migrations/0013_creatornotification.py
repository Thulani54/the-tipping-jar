import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("creators", "0012_creatorprofile_kyc_kycDocument"),
    ]

    operations = [
        migrations.CreateModel(
            name="CreatorNotification",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("notification_type", models.CharField(
                    choices=[
                        ("welcome",        "Welcome"),
                        ("first_tip",      "First Tip"),
                        ("tip_received",   "Tip Received"),
                        ("tip_goal",       "Tip Goal Reached"),
                        ("first_jar",      "First Jar Created"),
                        ("first_thousand", "First R1 000"),
                        ("summary",        "Tips Summary"),
                    ],
                    max_length=20,
                )),
                ("title",      models.CharField(max_length=200)),
                ("message",    models.TextField()),
                ("is_read",    models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "creator",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="notifications",
                        to="creators.creatorprofile",
                    ),
                ),
            ],
            options={
                "ordering": ["-created_at"],
            },
        ),
    ]
