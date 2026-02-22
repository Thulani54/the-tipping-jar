from django.db import migrations, models


def reset_two_fa_for_all(apps, schema_editor):
    """
    Set two_fa_enabled=False for ALL users.
    SMTP delivery from Azure is unreliable, so 2FA is opt-in only.
    Users who want 2FA can re-enable it from their profile settings
    once email delivery is confirmed working.
    """
    User = apps.get_model("users", "User")
    User.objects.filter(two_fa_enabled=True).update(two_fa_enabled=False)


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0005_user_two_fa_enabled"),
    ]

    operations = [
        migrations.AlterField(
            model_name="user",
            name="two_fa_enabled",
            field=models.BooleanField(
                default=False,
                help_text="When False, login skips the OTP step entirely.",
            ),
        ),
        migrations.RunPython(reset_two_fa_for_all, migrations.RunPython.noop),
    ]
