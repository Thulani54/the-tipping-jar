"""
Management command: send_daily_report
======================================
Send a nightly transaction report to every active creator who received at
least one completed tip on the previous calendar day (SAST midnight→midnight).

Intended schedule: run at 22:00 UTC every night = 00:00 SAST (+02:00).

    python manage.py send_daily_report            # live run
    python manage.py send_daily_report --dry-run  # print only, no emails
    python manage.py send_daily_report --date 2026-03-15  # specific date
"""
import datetime
import logging

from zoneinfo import ZoneInfo
from django.core.management.base import BaseCommand

from apps.creators.models import CreatorNotification, CreatorProfile
from apps.support.emails import send_daily_report_email
from apps.tips.models import Tip

logger = logging.getLogger(__name__)

SAST = ZoneInfo("Africa/Johannesburg")


class Command(BaseCommand):
    help = "Send nightly transaction report emails to creators who received tips yesterday."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Print what would be sent without actually sending any emails.",
        )
        parser.add_argument(
            "--date",
            type=str,
            default=None,
            help="Override the report date (YYYY-MM-DD in SAST). Defaults to yesterday.",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]

        # Determine "yesterday" in SAST time
        if options["date"]:
            try:
                report_date = datetime.date.fromisoformat(options["date"])
            except ValueError:
                self.stderr.write(self.style.ERROR(f"Invalid date: {options['date']}"))
                return
        else:
            report_date = datetime.datetime.now(tz=SAST).date() - datetime.timedelta(days=1)

        # Build SAST midnight→midnight boundaries, then convert to UTC for DB queries
        day_start_sast = datetime.datetime.combine(report_date, datetime.time.min, tzinfo=SAST)
        day_end_sast = day_start_sast + datetime.timedelta(days=1)
        day_start_utc = day_start_sast.astimezone(datetime.timezone.utc)
        day_end_utc = day_end_sast.astimezone(datetime.timezone.utc)

        date_label = report_date.strftime("%a %d %b %Y")  # e.g. "Mon 16 Mar 2026"

        self.stdout.write(f"Daily report for {date_label} ({day_start_utc} → {day_end_utc} UTC)")

        # Find distinct creators who received completed tips that day
        creator_ids = (
            Tip.objects.filter(
                status=Tip.Status.COMPLETED,
                created_at__gte=day_start_utc,
                created_at__lt=day_end_utc,
            )
            .values_list("creator_id", flat=True)
            .distinct()
        )

        profiles = CreatorProfile.objects.filter(id__in=creator_ids, is_active=True)
        self.stdout.write(f"Found {profiles.count()} creator(s) with tips on {date_label}")

        sent = 0
        for creator in profiles:
            tips = list(
                Tip.objects.filter(
                    creator=creator,
                    status=Tip.Status.COMPLETED,
                    created_at__gte=day_start_utc,
                    created_at__lt=day_end_utc,
                )
                .select_related("tipper", "jar")
                .order_by("created_at")
            )
            if not tips:
                continue

            total = sum(float(t.amount) for t in tips)
            self.stdout.write(
                f"  {creator.display_name} — {len(tips)} tip(s), R{total:.2f}"
            )

            if dry_run:
                continue

            try:
                send_daily_report_email(creator, date_label, tips)
            except Exception as exc:
                logger.exception("Failed to send daily report to %s: %s", creator.display_name, exc)
                self.stderr.write(
                    self.style.WARNING(f"  Failed for {creator.display_name}: {exc}")
                )
                continue

            # In-app notification
            CreatorNotification.objects.create(
                creator=creator,
                notification_type=CreatorNotification.Type.SUMMARY,
                title=f"Daily report — R{total:.2f} from {len(tips)} tip(s)",
                message=(
                    f"You received {len(tips)} tip(s) totalling R{total:.2f} on {date_label}. "
                    "Check your email for the full breakdown."
                ),
            )
            sent += 1

        action = "Would send" if dry_run else "Sent"
        self.stdout.write(self.style.SUCCESS(f"{action} daily reports to {sent} creator(s)."))
