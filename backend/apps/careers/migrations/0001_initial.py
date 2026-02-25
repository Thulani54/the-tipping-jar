from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="JobOpening",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("title", models.CharField(max_length=200)),
                (
                    "department",
                    models.CharField(
                        choices=[
                            ("Engineering", "Engineering"),
                            ("Design", "Design"),
                            ("Growth", "Growth"),
                            ("Operations", "Operations"),
                            ("Marketing", "Marketing"),
                            ("Product", "Product"),
                            ("Finance", "Finance"),
                            ("Other", "Other"),
                        ],
                        default="Engineering",
                        max_length=30,
                    ),
                ),
                ("location", models.CharField(default="Remote", max_length=100)),
                (
                    "employment_type",
                    models.CharField(
                        choices=[
                            ("Full-time", "Full-time"),
                            ("Part-time", "Part-time"),
                            ("Contract", "Contract"),
                            ("Internship", "Internship"),
                        ],
                        default="Full-time",
                        max_length=20,
                    ),
                ),
                ("description", models.TextField(blank=True)),
                ("is_active", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={
                "verbose_name": "Job Opening",
                "verbose_name_plural": "Job Openings",
                "ordering": ["department", "title"],
            },
        ),
    ]
