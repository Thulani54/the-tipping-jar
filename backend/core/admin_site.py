"""
Custom Django admin site for TippingJar.

Overrides the default admin `index` to inject dashboard statistics
(tips, users, support queue, SMS credits) into the template context.
"""

import logging

from django.contrib import admin
from django.db.models import Count, Sum
from django.utils import timezone

logger = logging.getLogger(__name__)


class TippingJarAdminSite(admin.AdminSite):
    site_header = "TippingJar Administration"
    site_title = "TippingJar Admin"
    index_title = "Dashboard"

    def index(self, request, extra_context=None):
        """Render the admin index with live dashboard stats."""
        ctx = extra_context or {}
        ctx.update(self._gather_stats())
        return super().index(request, extra_context=ctx)

    def _gather_stats(self) -> dict:
        try:
            from apps.creators.models import CreatorProfile
            from apps.support.models import ContactMessage, Dispute
            from apps.support.sms import get_sms_credits
            from apps.tips.models import Tip
            from apps.users.models import OTP, User

            today = timezone.now().date()
            month_start = today.replace(day=1)

            # ── Tips ──────────────────────────────────────────────────────────
            tips_qs = Tip.objects.all()
            completed = tips_qs.filter(status="completed")
            tips_value = completed.aggregate(v=Sum("amount"))["v"] or 0
            tips_this_month = completed.filter(created_at__date__gte=month_start)
            tips_month_value = tips_this_month.aggregate(v=Sum("amount"))["v"] or 0
            tips_today_count = completed.filter(created_at__date=today).count()

            # ── Users ─────────────────────────────────────────────────────────
            users_by_role = User.objects.values("role").annotate(n=Count("id"))
            role_map = {r["role"]: r["n"] for r in users_by_role}

            # ── Support ───────────────────────────────────────────────────────
            dispute_counts = (
                Dispute.objects.values("status").annotate(n=Count("id"))
            )
            dispute_map = {d["status"]: d["n"] for d in dispute_counts}

            # ── OTP stats ─────────────────────────────────────────────────────
            otp_today = OTP.objects.filter(created_at__date=today)
            otp_by_method = otp_today.values("method").annotate(n=Count("id"))
            otp_method_map = {o["method"]: o["n"] for o in otp_by_method}

            # ── SMS credits ───────────────────────────────────────────────────
            sms_data = get_sms_credits()

            # ── Recent ────────────────────────────────────────────────────────
            recent_tips = (
                Tip.objects.select_related("creator", "tipper")
                .order_by("-created_at")[:8]
            )
            recent_users = User.objects.order_by("-date_joined")[:8]

            return {
                # Tips
                "tips_total": completed.count(),
                "tips_value": tips_value,
                "tips_pending": tips_qs.filter(status="pending").count(),
                "tips_failed": tips_qs.filter(status="failed").count(),
                "tips_today": tips_today_count,
                "tips_month_value": tips_month_value,
                # Users
                "users_total": User.objects.count(),
                "users_fans": role_map.get("fan", 0),
                "users_creators": role_map.get("creator", 0),
                "users_new_month": User.objects.filter(date_joined__date__gte=month_start).count(),
                # Creators
                "creators_active": CreatorProfile.objects.filter(is_active=True).count(),
                # Support
                "contacts_pending": ContactMessage.objects.filter(is_resolved=False).count(),
                "disputes_open": dispute_map.get("open", 0),
                "disputes_investigating": dispute_map.get("investigating", 0),
                "disputes_resolved": dispute_map.get("resolved", 0),
                # OTP
                "otp_email_today": otp_method_map.get("email", 0),
                "otp_sms_today": otp_method_map.get("sms", 0),
                # SMS Portal
                "sms_credits": sms_data.get("credits"),
                "sms_credits_raw": sms_data.get("raw", ""),
                "sms_configured": bool(sms_data.get("success")),
                # Recent activity
                "recent_tips": recent_tips,
                "recent_users": recent_users,
            }
        except Exception as exc:
            logger.exception("Admin dashboard stats error: %s", exc)
            return {"stats_error": str(exc)}


# Singleton — replaces the default admin.site
admin_site = TippingJarAdminSite(name="tippingjar_admin")
