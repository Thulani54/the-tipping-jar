import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0002_add_apikey_model"),
    ]

    operations = [
        # Add phone_number to User
        migrations.AddField(
            model_name="user",
            name="phone_number",
            field=models.CharField(
                blank=True,
                max_length=20,
                help_text="International format, e.g. +27821234567. Required for SMS OTP.",
            ),
        ),
        # Add otp_method to User
        migrations.AddField(
            model_name="user",
            name="otp_method",
            field=models.CharField(
                choices=[("email", "Email"), ("sms", "SMS")],
                default="email",
                max_length=5,
                help_text="Preferred OTP delivery channel.",
            ),
        ),
        # Create OTP model
        migrations.CreateModel(
            name="OTP",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("code", models.CharField(max_length=6)),
                ("method", models.CharField(
                    choices=[("email", "Email"), ("sms", "SMS")],
                    default="email",
                    max_length=5,
                )),
                ("is_used", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("expires_at", models.DateTimeField()),
                ("user", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="otps",
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                "ordering": ["-created_at"],
            },
        ),
    ]
