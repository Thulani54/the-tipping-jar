from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("creators", "0006_creatorprofile_paystack_subaccount_code_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="creatorprofile",
            name="thank_you_message",
            field=models.TextField(
                blank=True,
                default="",
                help_text="Custom thank-you note sent to tippers after a successful payment.",
            ),
        ),
    ]
