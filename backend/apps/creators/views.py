import datetime
import logging

from django.conf import settings
from django.db.models import Sum, Count
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.payments import paystack as ps
from .models import CreatorProfile, Jar
from .serializers import CreatorProfileSerializer, JarSerializer

logger = logging.getLogger(__name__)


def _maybe_create_paystack_subaccount(profile: CreatorProfile) -> None:
    """
    Create a Paystack subaccount for the creator if:
      - PAYSTACK_SECRET_KEY is configured
      - The creator has bank details set
      - No subaccount code exists yet
    The bank_routing_number field holds the Paystack bank code (e.g. "632005" for ABSA).
    """
    if not settings.PAYSTACK_SECRET_KEY:
        return
    if profile.paystack_subaccount_code:
        return  # already created
    if not (profile.bank_account_number and profile.bank_routing_number):
        return  # missing bank details

    try:
        sub = ps.create_subaccount(
            business_name=profile.display_name or profile.user.username,
            settlement_bank=profile.bank_routing_number,   # bank code
            account_number=profile.bank_account_number,
            percentage_charge=settings.PLATFORM_FEE_PERCENT,
        )
        profile.paystack_subaccount_code = sub.get("subaccount_code", "")
        profile.paystack_subaccount_id   = str(sub.get("id", ""))
        profile.save(update_fields=["paystack_subaccount_code", "paystack_subaccount_id"])
        logger.info(
            "Created Paystack subaccount %s for creator %s",
            profile.paystack_subaccount_code, profile.slug,
        )
    except RuntimeError as exc:
        logger.warning("Paystack subaccount creation failed for %s: %s", profile.slug, exc)


class CreatorListView(generics.ListAPIView):
    queryset = CreatorProfile.objects.filter(is_active=True).order_by("-created_at")
    serializer_class = CreatorProfileSerializer
    permission_classes = [permissions.AllowAny]


class CreatorDetailView(generics.RetrieveAPIView):
    queryset = CreatorProfile.objects.filter(is_active=True)
    serializer_class = CreatorProfileSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = "slug"


class MyCreatorProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = CreatorProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        profile, _ = CreatorProfile.objects.get_or_create(
            user=self.request.user,
            defaults={
                "slug": self.request.user.username,
                "display_name": self.request.user.username,
            },
        )
        return profile

    def perform_update(self, serializer):
        profile = serializer.save()
        # Auto-provision Paystack subaccount when banking details are saved
        _maybe_create_paystack_subaccount(profile)


class MyDashboardStatsView(APIView):
    """Aggregate stats for the authenticated creator's dashboard."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        try:
            profile = CreatorProfile.objects.get(user=request.user)
        except CreatorProfile.DoesNotExist:
            return Response(
                {"detail": "Creator profile not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        completed = profile.tips.filter(status="completed")

        total_earned = float(
            completed.aggregate(t=Sum("amount"))["t"] or 0
        )

        now = timezone.now()
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        this_month = float(
            completed.filter(created_at__gte=month_start)
            .aggregate(t=Sum("amount"))["t"] or 0
        )

        tip_count = completed.count()

        # Weekly earnings — last 7 calendar days (oldest → newest)
        weekly_data = []
        week_labels = []
        for i in range(6, -1, -1):
            day = now - datetime.timedelta(days=i)
            day_start = day.replace(hour=0, minute=0, second=0, microsecond=0)
            day_end = day.replace(hour=23, minute=59, second=59, microsecond=999999)
            day_total = float(
                completed.filter(created_at__range=(day_start, day_end))
                .aggregate(t=Sum("amount"))["t"] or 0
            )
            weekly_data.append(day_total)
            week_labels.append(day.strftime("%a"))

        # Top fans by total amount sent
        top_fans = list(
            completed.values("tipper_name")
            .annotate(total=Sum("amount"))
            .order_by("-total")[:5]
        )

        return Response(
            {
                "total_earned": total_earned,
                "this_month_earned": this_month,
                "tip_count": tip_count,
                "pending_payout": 0.0,  # populated once Stripe payouts are live
                "weekly_data": weekly_data,
                "week_labels": week_labels,
                "top_fans": [
                    {"name": f["tipper_name"], "total": float(f["total"])}
                    for f in top_fans
                ],
            }
        )


# ── Jar views ─────────────────────────────────────────────────────────────────

class MyJarListCreateView(generics.ListCreateAPIView):
    """Authenticated creator: list own jars or create a new one."""

    serializer_class = JarSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return Jar.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return Jar.objects.none()

    def perform_create(self, serializer):
        profile = CreatorProfile.objects.get(user=self.request.user)
        serializer.save(creator=profile)


class MyJarDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Authenticated creator: retrieve, update, or delete a specific jar."""

    serializer_class = JarSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return Jar.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return Jar.objects.none()


class PublicCreatorJarsView(generics.ListAPIView):
    """Public: list active jars for a creator by slug."""

    serializer_class = JarSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        slug = self.kwargs["slug"]
        return Jar.objects.filter(creator__slug=slug, is_active=True)


class PublicJarDetailView(generics.RetrieveAPIView):
    """Public: get a single jar by creator slug + jar slug."""

    serializer_class = JarSerializer
    permission_classes = [permissions.AllowAny]

    def get_object(self):
        from django.shortcuts import get_object_or_404
        return get_object_or_404(
            Jar,
            creator__slug=self.kwargs["slug"],
            slug=self.kwargs["jar_slug"],
            is_active=True,
        )
