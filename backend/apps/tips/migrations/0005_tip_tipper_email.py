from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("tips", "0004_tip_creator_net_tip_paystack_reference_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="tip",
            name="tipper_email",
            field=models.EmailField(blank=True, default="", max_length=254),
        ),
    ]
