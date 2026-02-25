"""
Management command: seed_admin

Creates a default admin user if no user with role='admin' exists yet.
Credentials are read from env vars so they never live in source code:

    ADMIN_EMAIL    (default: admin@tippingjar.co.za)
    ADMIN_PASSWORD (default: TippingAdmin#2026)
    ADMIN_USERNAME (default: admin)
"""

import os

from django.core.management.base import BaseCommand

from apps.users.models import User


class Command(BaseCommand):
    help = "Create the default admin user if none exists."

    def handle(self, *args, **options):
        email = os.environ.get("ADMIN_EMAIL", "admin@tippingjar.co.za")
        password = os.environ.get("ADMIN_PASSWORD", "TippingAdmin#2026")
        username = os.environ.get("ADMIN_USERNAME", "admin")

        if User.objects.filter(role=User.Role.ADMIN).exists():
            self.stdout.write("Admin user already exists — skipping.")
            return

        if User.objects.filter(email=email).exists():
            # Promote the existing account to admin
            User.objects.filter(email=email).update(role=User.Role.ADMIN)
            self.stdout.write(self.style.SUCCESS(
                f"Existing user {email} promoted to admin."
            ))
            return

        User.objects.create_user(
            username=username,
            email=email,
            password=password,
            role=User.Role.ADMIN,
            is_staff=True,
        )
        self.stdout.write(self.style.SUCCESS(
            f"Admin user created: {email}"
        ))
