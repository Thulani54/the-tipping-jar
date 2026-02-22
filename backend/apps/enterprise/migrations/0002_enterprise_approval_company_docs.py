import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("enterprise", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="enterprise",
            name="approval_status",
            field=models.CharField(
                choices=[("pending", "Pending"), ("approved", "Approved"), ("rejected", "Rejected")],
                default="pending",
                max_length=10,
            ),
        ),
        migrations.AddField(
            model_name="enterprise",
            name="rejection_reason",
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name="enterprise",
            name="company_name_legal",
            field=models.CharField(blank=True, max_length=200),
        ),
        migrations.AddField(
            model_name="enterprise",
            name="company_registration_number",
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name="enterprise",
            name="vat_number",
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name="enterprise",
            name="contact_name",
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name="enterprise",
            name="contact_email",
            field=models.EmailField(blank=True, max_length=254),
        ),
        migrations.AddField(
            model_name="enterprise",
            name="contact_phone",
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.CreateModel(
            name="EnterpriseDocument",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False, verbose_name="ID"
                    ),
                ),
                (
                    "doc_type",
                    models.CharField(
                        choices=[
                            ("cipc", "Company Registration (CIPC)"),
                            ("vat", "VAT Certificate"),
                            ("id", "Director ID / Passport"),
                            ("bank", "Bank Confirmation Letter"),
                        ],
                        max_length=10,
                    ),
                ),
                ("file", models.FileField(upload_to="enterprise_docs/%Y/")),
                ("uploaded_at", models.DateTimeField(auto_now_add=True)),
                (
                    "enterprise",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="documents",
                        to="enterprise.enterprise",
                    ),
                ),
            ],
        ),
    ]
