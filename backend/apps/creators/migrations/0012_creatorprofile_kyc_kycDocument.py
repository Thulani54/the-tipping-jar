from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("creators", "0011_creatorprofile_audience_demographics"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # Change bank_country default from 'US' to 'ZA'
        migrations.AlterField(
            model_name="creatorprofile",
            name="bank_country",
            field=models.CharField(blank=True, default="ZA", max_length=2),
        ),
        # KYC status on CreatorProfile
        migrations.AddField(
            model_name="creatorprofile",
            name="kyc_status",
            field=models.CharField(
                choices=[
                    ("not_started", "Not Started"),
                    ("pending", "Pending Review"),
                    ("approved", "Approved"),
                    ("declined", "Declined"),
                ],
                default="not_started",
                max_length=15,
            ),
        ),
        migrations.AddField(
            model_name="creatorprofile",
            name="kyc_decline_reason",
            field=models.TextField(blank=True, default=""),
        ),
        # CreatorKycDocument model
        migrations.CreateModel(
            name="CreatorKycDocument",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("doc_type", models.CharField(
                    choices=[
                        ("national_id", "South African ID"),
                        ("passport", "Passport"),
                        ("proof_of_bank", "Proof of Bank Account"),
                        ("proof_of_address", "Proof of Address"),
                        ("selfie", "Selfie with ID"),
                    ],
                    max_length=20,
                )),
                ("file", models.FileField(upload_to="kyc/%Y/")),
                ("status", models.CharField(
                    choices=[
                        ("pending", "Pending"),
                        ("approved", "Approved"),
                        ("declined", "Declined"),
                    ],
                    default="pending",
                    max_length=10,
                )),
                ("decline_reason", models.TextField(blank=True, default="")),
                ("uploaded_at", models.DateTimeField(auto_now_add=True)),
                ("reviewed_at", models.DateTimeField(blank=True, null=True)),
                ("creator", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="kyc_documents",
                    to="creators.creatorprofile",
                )),
            ],
            options={"ordering": ["-uploaded_at"]},
        ),
    ]
