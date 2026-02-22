from django.db import migrations

from apps.users.management.commands.create_demo_users import reverse_seed, seed_demo_users


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0003_user_phone_otp_method_otp_model"),
        ("creators", "0010_tiers_milestones_commissions"),
    ]

    operations = [
        migrations.RunPython(seed_demo_users, reverse_seed),
    ]
