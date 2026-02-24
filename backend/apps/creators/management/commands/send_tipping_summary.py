"""
Management command: send_tipping_summary
=========================================
Send a 2-day tipping summary email to every active creator who received
at least one completed tip in the last 48 hours.

Run this via cron or Azure scheduler at midnight every 2 days:
  python manage.py send_tipping_summary

GitHub Actions schedule example (every 2 days at 00:00 UTC):
  - cron: '0 0 */2 * *'
"""
import datetime
import logging

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.creators.models import CreatorNotification, CreatorProfile
from apps.support.emails import send_tipping_summary_email
from apps.tips.models import Tip

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Send 2-day tipping summary emails to creators who received tips in the last 48 hours."

    def add_arguments(self, parser):
        parser.add_argument(
            "--hours",
            type=int,
            default=48,
            help="Look-back window in hours (default: 48)",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Print what would be sent without actually sending",
        )

    def handle(self, *args, **options):
        hours = options["hours"]
        dry_run = options["dry_run"]

        since = timezone.now() - datetime.timedelta(hours=hours)
        period_label = (
            f"{since.strftime('%d %b')} – {timezone.now().strftime('%d %b %Y')}"
        )

        # Find creators with completed tips in window
        creator_ids = (
            Tip.objects.filter(status=Tip.Status.COMPLETED, created_at__gte=since)
            .values_list("creator_id", flat=True)
            .distinct()
        )

        profiles = CreatorProfile.objects.filter(id__in=creator_ids, is_active=True)
        self.stdout.write(
            f"Found {profiles.count()} creator(s) with tips in the last {hours}h"
        )

        sent = 0
        for creator in profiles:
            tips = list(
                Tip.objects.filter(
                    creator=creator,
                    status=Tip.Status.COMPLETED,
                    created_at__gte=since,
                ).order_by("-created_at")
            )
            if not tips:
                continue

            total = sum(float(t.amount) for t in tips)
            self.stdout.write(
                f"  {creator.display_name} — {len(tips)} tip(s), R{total:.2f}"
            )

            if dry_run:
                continue

            send_tipping_summary_email(creator, period_label, tips)

            # In-app summary notification
            CreatorNotification.objects.create(
                creator=creator,
                notification_type=CreatorNotification.Type.SUMMARY,
                title=f"Tips summary — R{total:.2f} in {len(tips)} tip(s)",
                message=f"You received {len(tips)} tip(s) totalling R{total:.2f} in the last {hours} hours.",
            )
            sent += 1

        action = "Would send" if dry_run else "Sent"
        self.stdout.write(self.style.SUCCESS(f"{action} summaries to {sent} creator(s)."))
