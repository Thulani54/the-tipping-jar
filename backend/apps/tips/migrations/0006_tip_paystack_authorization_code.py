from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("tips", "0005_tip_tipper_email"),
    ]

    operations = [
        migrations.AddField(
            model_name="tip",
            name="paystack_authorization_code",
            field=models.CharField(blank=True, max_length=200),
        ),
    ]
