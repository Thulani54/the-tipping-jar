"""
Internal cron / scheduler views.
These endpoints are called by GitHub Actions (or any scheduler) to run
management-command-equivalent logic without needing container SSH.

All endpoints require the header:
    X-Cron-Secret: <value of CRON_SECRET env var>

If CRON_SECRET is not set the endpoint is disabled (returns 403).
"""
import datetime
import logging
from zoneinfo import ZoneInfo

from django.conf import settings
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views import View
from django.views.decorators.csrf import csrf_exempt

logger = logging.getLogger(__name__)

SAST = ZoneInfo("Africa/Johannesburg")


def _check_secret(request):
    secret = getattr(settings, "CRON_SECRET", "")
    if not secret:
        return False
    return request.headers.get("X-Cron-Secret", "") == secret


@method_decorator(csrf_exempt, name="dispatch")
class DailyReportView(View):
    """
    POST /api/cron/daily-report/
    Headers: X-Cron-Secret: <CRON_SECRET>
    Body (optional JSON):
        { "date": "2026-03-16", "dry_run": false }
    """

    def post(self, request, *args, **kwargs):
        if not _check_secret(request):
            return JsonResponse({"error": "Forbidden"}, status=403)

        import json
        from apps.creators.models import CreatorNotification, CreatorProfile
        from apps.support.emails import send_daily_report_email
        from apps.tips.models import Tip

        # Parse optional body
        try:
            body = json.loads(request.body or "{}")
        except Exception:
            body = {}

        dry_run = bool(body.get("dry_run", False))
        date_str = body.get("date", "")

        # Determine report date (yesterday in SAST by default)
        if date_str:
            try:
                report_date = datetime.date.fromisoformat(date_str)
            except ValueError:
                return JsonResponse({"error": f"Invalid date: {date_str}"}, status=400)
        else:
            report_date = datetime.datetime.now(tz=SAST).date() - datetime.timedelta(days=1)

        day_start_sast = datetime.datetime.combine(report_date, datetime.time.min, tzinfo=SAST)
        day_end_sast   = day_start_sast + datetime.timedelta(days=1)
        day_start_utc  = day_start_sast.astimezone(datetime.timezone.utc)
        day_end_utc    = day_end_sast.astimezone(datetime.timezone.utc)
        date_label     = report_date.strftime("%a %d %b %Y")

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
        results = []
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
            results.append({
                "creator": creator.display_name,
                "email": creator.user.email,
                "tips": len(tips),
                "total": round(total, 2),
                "sent": not dry_run,
            })

            if dry_run:
                continue

            try:
                send_daily_report_email(creator, date_label, tips)
            except Exception as exc:
                logger.exception("DailyReportView: failed for %s: %s", creator.display_name, exc)
                results[-1]["sent"] = False
                results[-1]["error"] = str(exc)
                continue

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

        return JsonResponse({
            "date": date_label,
            "dry_run": dry_run,
            "creators_found": len(results),
            "emails_sent": sent,
            "results": results,
        })
