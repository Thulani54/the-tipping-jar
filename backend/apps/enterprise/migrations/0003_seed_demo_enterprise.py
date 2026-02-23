from django.db import migrations


def seed_demo_enterprise(apps, schema_editor):
    User = apps.get_model("users", "User")
    Enterprise = apps.get_model("enterprise", "Enterprise")

    try:
        user = User.objects.get(email="enterprise@tippingjar.co.za")
    except User.DoesNotExist:
        return  # demo user not seeded yet — skip

    Enterprise.objects.get_or_create(
        admin=user,
        defaults={
            "name": "Demo Agency",
            "slug": "demo-agency",
            "plan": "growth",
            "approval_status": "approved",
            "company_name_legal": "Demo Agency (Pty) Ltd",
            "contact_name": "Enterprise Demo",
            "contact_email": "enterprise@tippingjar.co.za",
        },
    )


def reverse_demo_enterprise(apps, schema_editor):
    Enterprise = apps.get_model("enterprise", "Enterprise")
    Enterprise.objects.filter(slug="demo-agency").delete()


class Migration(migrations.Migration):

    dependencies = [
        ("enterprise", "0002_enterprise_approval_company_docs"),
        ("users", "0004_seed_demo_users"),
    ]

    operations = [
        migrations.RunPython(seed_demo_enterprise, reverse_demo_enterprise),
    ]
