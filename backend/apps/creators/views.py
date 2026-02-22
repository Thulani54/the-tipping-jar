import datetime
import logging

from django.conf import settings
from django.db.models import Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.payments import paystack as ps
from apps.tips.models import Tip

from .models import (
    CommissionRequest,
    CommissionSlot,
    CreatorPost,
    CreatorProfile,
    Jar,
    MilestoneGoal,
    SupportTier,
)
from .serializers import (
    CommissionRequestSerializer,
    CommissionSlotSerializer,
    CreatorPostPublicSerializer,
    CreatorPostSerializer,
    CreatorProfileSerializer,
    JarSerializer,
    MilestoneGoalSerializer,
    SupportTierSerializer,
)

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
        return get_object_or_404(
            Jar,
            creator__slug=self.kwargs["slug"],
            slug=self.kwargs["jar_slug"],
            is_active=True,
        )


# ── Creator post views ─────────────────────────────────────────────────────────

class MyPostListCreateView(generics.ListCreateAPIView):
    """Authenticated creator: list own posts or create a new one."""

    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    serializer_class = CreatorPostSerializer

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return CreatorPost.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return CreatorPost.objects.none()

    def perform_create(self, serializer):
        profile = CreatorProfile.objects.get(user=self.request.user)
        serializer.save(creator=profile)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


class MyPostDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Authenticated creator: retrieve, update, or delete a specific post."""

    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    serializer_class = CreatorPostSerializer

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return CreatorPost.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return CreatorPost.objects.none()

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


class PublicPostListView(generics.ListAPIView):
    """Public: list published post teasers (title + type only) for a creator."""

    serializer_class = CreatorPostPublicSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return CreatorPost.objects.filter(
            creator__slug=self.kwargs["slug"],
            is_published=True,
        )


class PostAccessView(APIView):
    """POST {email} → 200 with full posts if the email has a completed tip, else 403."""

    permission_classes = [permissions.AllowAny]

    def post(self, request, slug):
        email = request.data.get("email", "").strip().lower()
        if not email:
            return Response({"detail": "Email is required."}, status=status.HTTP_400_BAD_REQUEST)

        creator = get_object_or_404(CreatorProfile, slug=slug)
        has_tipped = Tip.objects.filter(
            creator=creator,
            tipper_email__iexact=email,
            status=Tip.Status.COMPLETED,
        ).exists()

        if not has_tipped:
            return Response(
                {"detail": "No completed tip found for this email."},
                status=status.HTTP_403_FORBIDDEN,
            )

        posts = creator.posts.filter(is_published=True)
        return Response(
            CreatorPostSerializer(posts, many=True, context={"request": request}).data
        )


# ── Support Tier views ────────────────────────────────────────────────────────

class PublicTierListView(generics.ListAPIView):
    """Public: list active support tiers for a creator."""

    serializer_class = SupportTierSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return SupportTier.objects.filter(
            creator__slug=self.kwargs["slug"], is_active=True
        )


class MyTierListCreateView(generics.ListCreateAPIView):
    """Creator: list own tiers or create a new one."""

    serializer_class = SupportTierSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return SupportTier.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return SupportTier.objects.none()

    def perform_create(self, serializer):
        profile = CreatorProfile.objects.get(user=self.request.user)
        serializer.save(creator=profile)


class MyTierDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Creator: update or delete a specific tier."""

    serializer_class = SupportTierSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return SupportTier.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return SupportTier.objects.none()


# ── Milestone views ───────────────────────────────────────────────────────────

class PublicMilestoneListView(generics.ListAPIView):
    """Public: list active milestones for a creator (includes current_month_total)."""

    serializer_class = MilestoneGoalSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return MilestoneGoal.objects.filter(
            creator__slug=self.kwargs["slug"], is_active=True
        )


class MyMilestoneListCreateView(generics.ListCreateAPIView):
    """Creator: list own milestones or create a new one."""

    serializer_class = MilestoneGoalSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return MilestoneGoal.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return MilestoneGoal.objects.none()

    def perform_create(self, serializer):
        profile = CreatorProfile.objects.get(user=self.request.user)
        serializer.save(creator=profile)


class MyMilestoneDetailView(generics.RetrieveUpdateAPIView):
    """Creator: update a specific milestone."""

    serializer_class = MilestoneGoalSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return MilestoneGoal.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return MilestoneGoal.objects.none()


# ── Commission views ──────────────────────────────────────────────────────────

class MyCommissionSlotView(APIView):
    """Creator: get or update their commission slot settings."""

    permission_classes = [permissions.IsAuthenticated]

    def _get_profile(self):
        return get_object_or_404(CreatorProfile, user=self.request.user)

    def get(self, request):
        profile = self._get_profile()
        slot, _ = CommissionSlot.objects.get_or_create(creator=profile)
        return Response(CommissionSlotSerializer(slot).data)

    def put(self, request):
        profile = self._get_profile()
        slot, _ = CommissionSlot.objects.get_or_create(creator=profile)
        serializer = CommissionSlotSerializer(slot, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class MyCommissionRequestListView(generics.ListAPIView):
    """Creator: list incoming commission requests."""

    serializer_class = CommissionRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return CommissionRequest.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return CommissionRequest.objects.none()


class MyCommissionRequestDetailView(generics.UpdateAPIView):
    """Creator: accept, decline, or complete a commission request."""

    serializer_class = CommissionRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return CommissionRequest.objects.filter(creator=profile)
        except CreatorProfile.DoesNotExist:
            return CommissionRequest.objects.none()


class PublicCommissionRequestCreateView(APIView):
    """Public: fan submits a commission request to a creator."""

    permission_classes = [permissions.AllowAny]

    def post(self, request, slug):
        creator = get_object_or_404(CreatorProfile, slug=slug)
        slot = getattr(creator, "commission_slot", None)
        if not slot or not slot.is_open:
            return Response(
                {"detail": "This creator is not accepting commissions."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = {**request.data, "creator": creator.id}
        serializer = CommissionRequestSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        commission = serializer.save(
            creator=creator,
            fan=request.user if request.user.is_authenticated else None,
        )
        return Response(CommissionRequestSerializer(commission).data, status=status.HTTP_201_CREATED)


# ── Creator incoming pledges ──────────────────────────────────────────────────

class CreatorIncomingPledgesView(generics.ListAPIView):
    """Creator: list incoming pledges from fans."""

    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        from apps.tips.serializers import PledgeSerializer
        return PledgeSerializer

    def get_queryset(self):
        from apps.tips.models import Pledge
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return Pledge.objects.filter(creator=profile).select_related("fan", "tier")
        except CreatorProfile.DoesNotExist:
            from apps.tips.models import Pledge
            return Pledge.objects.none()
