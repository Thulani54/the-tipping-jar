from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("creators", "0008_creatorpost"),
    ]

    operations = [
        migrations.AddField(
            model_name="creatorprofile",
            name="category",
            field=models.CharField(blank=True, default="", max_length=50),
        ),
        migrations.AddField(
            model_name="creatorprofile",
            name="platforms",
            field=models.CharField(blank=True, default="", max_length=200),
        ),
        migrations.AddField(
            model_name="creatorprofile",
            name="audience_size",
            field=models.CharField(blank=True, default="", max_length=50),
        ),
    ]
