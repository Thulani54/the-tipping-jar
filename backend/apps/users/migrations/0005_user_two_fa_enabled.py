from django.db import migrations, models

DEMO_EMAILS = [
    "enterprise@tippingjar.co.za",
    "creator@tippingjar.co.za",
    "fan@tippingjar.co.za",
]


def disable_demo_2fa(apps, schema_editor):
    User = apps.get_model("users", "User")
    User.objects.filter(email__in=DEMO_EMAILS).update(two_fa_enabled=False)


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0004_seed_demo_users"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="two_fa_enabled",
            field=models.BooleanField(
                default=True,
                help_text="When False, login skips the OTP step entirely.",
            ),
        ),
        migrations.RunPython(disable_demo_2fa, migrations.RunPython.noop),
    ]
