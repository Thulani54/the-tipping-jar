from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("creators", "0013_creatornotification"),
    ]

    operations = [
        migrations.AddField(
            model_name="creatorprofile",
            name="paystack_split_code",
            field=models.CharField(
                blank=True,
                default="",
                help_text="Paystack split code (SPL_xxxx) — routes platform fee + creator payout",
                max_length=100,
            ),
            preserve_default=False,
        ),
    ]
