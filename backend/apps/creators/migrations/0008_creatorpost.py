import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("creators", "0007_creatorprofile_thank_you_message"),
    ]

    operations = [
        migrations.CreateModel(
            name="CreatorPost",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("title", models.CharField(max_length=200)),
                ("body", models.TextField(blank=True, default="")),
                ("media_file", models.FileField(blank=True, null=True, upload_to="posts/")),
                ("video_url", models.URLField(blank=True, default="")),
                ("post_type", models.CharField(
                    choices=[("text", "Text"), ("image", "Image"), ("video", "Video"), ("file", "File")],
                    default="text",
                    max_length=10,
                )),
                ("is_published", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("creator", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="posts",
                    to="creators.creatorprofile",
                )),
            ],
            options={
                "ordering": ["-created_at"],
            },
        ),
    ]
