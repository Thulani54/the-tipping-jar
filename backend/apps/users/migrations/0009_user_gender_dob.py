from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0008_delete_thulanik544"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="gender",
            field=models.CharField(
                blank=True,
                choices=[
                    ("male", "Male"),
                    ("female", "Female"),
                    ("non_binary", "Non-binary"),
                    ("prefer_not_to_say", "Prefer not to say"),
                ],
                default="",
                help_text="User's gender identity.",
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name="user",
            name="date_of_birth",
            field=models.DateField(
                blank=True,
                null=True,
                help_text="User's date of birth (YYYY-MM-DD).",
            ),
        ),
    ]
