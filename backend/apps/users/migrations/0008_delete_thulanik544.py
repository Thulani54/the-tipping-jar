from django.db import migrations


def delete_thulanik544(apps, schema_editor):
    User = apps.get_model("users", "User")
    qs = User.objects.filter(email="thulanik544@gmail.com").exclude(is_superuser=True)
    count = qs.count()
    if count:
        print(f"\n  [cleanup] Deleting {count} account(s) with email thulanik544@gmail.com")
        qs.delete()
    else:
        print("\n  [cleanup] thulanik544@gmail.com not found — nothing to delete.")


def reverse_delete(apps, schema_editor):
    pass  # irreversible


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0007_delete_test_accounts"),
    ]

    operations = [
        migrations.RunPython(delete_thulanik544, reverse_delete),
    ]
