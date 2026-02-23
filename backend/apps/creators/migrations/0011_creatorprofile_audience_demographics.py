from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("creators", "0010_tiers_milestones_commissions"),
    ]

    operations = [
        migrations.AddField(
            model_name="creatorprofile",
            name="age_group",
            field=models.CharField(blank=True, default="", max_length=50),
        ),
        migrations.AddField(
            model_name="creatorprofile",
            name="audience_gender",
            field=models.CharField(blank=True, default="", max_length=30),
        ),
    ]
