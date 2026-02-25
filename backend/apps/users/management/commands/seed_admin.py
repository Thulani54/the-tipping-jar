"""
Management command: seed_admin

Ensures the designated admin account exists and has correct credentials.
Runs on every container start (idempotent — safe to run repeatedly).

Credentials are read from env vars:
    ADMIN_EMAIL    (default: admin@tippingjar.co.za)
    ADMIN_PASSWORD (default: TippingAdmin#2026)
    ADMIN_USERNAME (default: admin)
"""

import os

from django.core.management.base import BaseCommand

from apps.users.models import User


class Command(BaseCommand):
    help = "Ensure the admin account exists with correct credentials."

    def handle(self, *args, **options):
        email    = os.environ.get("ADMIN_EMAIL",    "admin@tippingjar.co.za")
        password = os.environ.get("ADMIN_PASSWORD", "TippingAdmin#2026")
        username = os.environ.get("ADMIN_USERNAME", "admin")

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            User.objects.create_user(
                username=username,
                email=email,
                password=password,
                role=User.Role.ADMIN,
                is_staff=True,
                two_fa_enabled=False,
            )
            self.stdout.write(self.style.SUCCESS(f"Admin user created: {email}"))
            return

        # User found — ensure every field is correct.
        changed = []
        if user.role != User.Role.ADMIN:
            user.role = User.Role.ADMIN
            changed.append("role")
        if not user.is_active:
            user.is_active = True
            changed.append("is_active")
        if not user.is_staff:
            user.is_staff = True
            changed.append("is_staff")
        if getattr(user, "two_fa_enabled", False):
            user.two_fa_enabled = False
            changed.append("two_fa_enabled")
        if not user.check_password(password):
            user.set_password(password)
            changed.append("password")

        if changed:
            user.save()
            self.stdout.write(self.style.SUCCESS(
                f"Admin user {email} fixed: {', '.join(changed)}"
            ))
        else:
            self.stdout.write(f"Admin user {email} — OK.")
