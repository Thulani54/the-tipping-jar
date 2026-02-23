from django.db import migrations
from django.db.models import Q


def delete_test_accounts(apps, schema_editor):
    User = apps.get_model("users", "User")

    qs = User.objects.filter(
        Q(email__icontains="thulani") |
        Q(email__icontains="test") |
        Q(username__icontains="test")
    ).exclude(is_superuser=True)  # never touch superuser accounts

    count = qs.count()
    if count:
        print(f"\n  [cleanup] Deleting {count} test/thulani account(s):")
        for u in qs:
            print(f"    - {u.email} (username={u.username})")
        qs.delete()
    else:
        print("\n  [cleanup] No test accounts found — nothing to delete.")


def reverse_test_accounts(apps, schema_editor):
    # Irreversible — accounts deleted for good
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0006_user_two_fa_default_false"),
    ]

    operations = [
        migrations.RunPython(delete_test_accounts, reverse_test_accounts),
    ]
