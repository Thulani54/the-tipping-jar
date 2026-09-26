import datetime
import logging

from django.conf import settings
from django.db import models
from django.db.models import Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.payments import paystack as ps
from apps.support.emails import send_banking_confirmed
from apps.tips.models import Tip

from .models import (
    CommissionRequest,
    CommissionSlot,
    CreatorKycDocument,
    CreatorPost,
    CreatorProfile,
    Jar,
    LiveStream,
    LiveStreamComment,
    LiveStreamGoal,
    LiveStreamPoll,
    LiveStreamPollOption,
    LiveStreamReaction,
    MilestoneGoal,
    SupportTier,
)
from .serializers import (
    CommissionRequestSerializer,
    CommissionSlotSerializer,
    CreatorPostFeedSerializer,
    CreatorPostPublicSerializer,
    CreatorPostSerializer,
    CreatorProfileSerializer,
    JarSerializer,
    KycDocumentSerializer,
    LiveStreamCommentSerializer,
    LiveStreamGoalSerializer,
    LiveStreamPollSerializer,
    LiveStreamSerializer,
    LiveStreamWithCreatorSerializer,
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
            settlement_bank=profile.bank_routing_number,
            account_number=profile.bank_account_number,
            percentage_charge=0,  # split handles all routing; master gets 0%
        )
        profile.paystack_subaccount_code = sub.get("subaccount_code", "")
        profile.paystack_subaccount_id   = str(sub.get("id", ""))
        profile.save(update_fields=["paystack_subaccount_code", "paystack_subaccount_id"])
        logger.info(
            "Created Paystack subaccount %s for creator %s",
            profile.paystack_subaccount_code, profile.slug,
        )

        # Create the transaction split: IMALI BADALA 3% + creator 97%
        platform_sub = getattr(settings, "PAYSTACK_PLATFORM_SUBACCOUNT_CODE", "")
        if platform_sub:
            split = ps.create_split(
                name=f"TippingJar — {profile.slug}",
                creator_subaccount_code=profile.paystack_subaccount_code,
                platform_subaccount_code=platform_sub,
                platform_share=settings.PLATFORM_FEE_PERCENT,
            )
            profile.paystack_split_code = split.get("split_code", "")
            profile.save(update_fields=["paystack_split_code"])
            logger.info("Created split %s for creator %s", profile.paystack_split_code, profile.slug)

        send_banking_confirmed(profile)
    except RuntimeError as exc:
        logger.warning("Paystack subaccount creation failed for %s: %s", profile.slug, exc)


class ValidateBankAccountView(APIView):
    """
    POST /api/creators/me/banking/validate/

    Validate a bank account number against a Paystack bank code.
    Returns the resolved account name so the creator can confirm before saving.

    Request body: { "account_number": "...", "bank_code": "..." }
    Response:     { "account_name": "...", "account_number": "..." }
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        account_number = request.data.get("account_number", "").strip()
        bank_code = request.data.get("bank_code", "").strip()

        if not account_number or not bank_code:
            return Response(
                {"detail": "account_number and bank_code are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not settings.PAYSTACK_SECRET_KEY:
            # Dev mode — skip real validation
            return Response({"account_name": "Dev Mode Account", "account_number": account_number})

        try:
            data = ps.resolve_account(account_number, bank_code)
        except RuntimeError:
            # Paystack's resolve endpoint only supports NGN/GHS/KES/USD regions.
            # For SA (ZAR) banks, skip client-side validation — the subaccount
            # creation step will catch any invalid account numbers.
            return Response({"skipped": True, "account_number": account_number})

        return Response({
            "skipped": False,
            "account_name": data.get("account_name", ""),
            "account_number": data.get("account_number", account_number),
        })


class CreatorListView(generics.ListAPIView):
    """Only return creators with a Paystack subaccount (i.e. bank verified & ready to receive tips)."""
    queryset = CreatorProfile.objects.filter(
        is_active=True,
    ).exclude(paystack_subaccount_code="").order_by("-created_at")
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


# ── KYC document views ────────────────────────────────────────────────────────

class MyKycDocumentListCreateView(APIView):
    """Creator: list own KYC documents or upload a new one."""

    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def _get_profile(self):
        return get_object_or_404(CreatorProfile, user=self.request.user)

    def get(self, request):
        profile = self._get_profile()
        docs = profile.kyc_documents.all()
        return Response(KycDocumentSerializer(docs, many=True, context={"request": request}).data)

    def post(self, request):
        profile = self._get_profile()
        doc_type = request.data.get("doc_type")
        file = request.FILES.get("file")

        if not doc_type or not file:
            return Response({"detail": "doc_type and file are required."}, status=status.HTTP_400_BAD_REQUEST)

        valid_types = [c[0] for c in CreatorKycDocument.DocType.choices]
        if doc_type not in valid_types:
            return Response({"detail": f"Invalid doc_type. Choose from: {valid_types}"}, status=status.HTTP_400_BAD_REQUEST)

        # Replace existing doc of same type (re-upload resets to pending)
        profile.kyc_documents.filter(doc_type=doc_type).delete()
        doc = CreatorKycDocument.objects.create(
            creator=profile,
            doc_type=doc_type,
            file=file,
            status=CreatorKycDocument.DocStatus.PENDING,
        )

        # Move overall KYC status to pending if not already approved
        if profile.kyc_status != CreatorProfile.KycStatus.APPROVED:
            profile.kyc_status = CreatorProfile.KycStatus.PENDING
            profile.save(update_fields=["kyc_status"])

        return Response(KycDocumentSerializer(doc, context={"request": request}).data, status=status.HTTP_201_CREATED)


class AdminKycApproveView(APIView):
    """Admin: approve a creator's KYC — grants full access."""

    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        profile = get_object_or_404(CreatorProfile, pk=pk)
        profile.kyc_documents.filter(status=CreatorKycDocument.DocStatus.PENDING).update(
            status=CreatorKycDocument.DocStatus.APPROVED,
        )
        profile.kyc_status = CreatorProfile.KycStatus.APPROVED
        profile.kyc_decline_reason = ""
        profile.save(update_fields=["kyc_status", "kyc_decline_reason"])
        return Response({"detail": "KYC approved."})


class AdminKycDeclineView(APIView):
    """Admin: decline a creator's KYC with a reason. Optionally decline specific docs."""

    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        profile = get_object_or_404(CreatorProfile, pk=pk)
        reason = request.data.get("reason", "")
        declined_doc_ids = request.data.get("doc_ids", [])  # optional list of doc IDs to decline

        if declined_doc_ids:
            doc_reason = request.data.get("doc_reason", reason)
            profile.kyc_documents.filter(id__in=declined_doc_ids).update(
                status=CreatorKycDocument.DocStatus.DECLINED,
                decline_reason=doc_reason,
            )
        else:
            # Decline all pending docs
            profile.kyc_documents.filter(status=CreatorKycDocument.DocStatus.PENDING).update(
                status=CreatorKycDocument.DocStatus.DECLINED,
                decline_reason=reason,
            )

        profile.kyc_status = CreatorProfile.KycStatus.DECLINED
        profile.kyc_decline_reason = reason
        profile.save(update_fields=["kyc_status", "kyc_decline_reason"])
        return Response({"detail": "KYC declined."})


# ── Creator notifications ─────────────────────────────────────────────────────

class MyNotificationsView(APIView):
    """
    GET  /api/creators/me/notifications/         — list last 50 notifications
    POST /api/creators/me/notifications/read/    — mark all as read
    """

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        try:
            creator = CreatorProfile.objects.get(user=request.user)
        except CreatorProfile.DoesNotExist:
            return Response([])
        notifications = creator.notifications.all()[:50]
        data = [
            {
                "id": n.id,
                "type": n.notification_type,
                "title": n.title,
                "message": n.message,
                "is_read": n.is_read,
                "created_at": n.created_at,
            }
            for n in notifications
        ]
        return Response(data)


class MarkNotificationsReadView(APIView):
    """POST /api/creators/me/notifications/read/ — mark all notifications as read."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            creator = CreatorProfile.objects.get(user=request.user)
        except CreatorProfile.DoesNotExist:
            return Response({"detail": "No creator profile."}, status=status.HTTP_404_NOT_FOUND)
        updated = creator.notifications.filter(is_read=False).update(is_read=True)
        return Response({"detail": f"{updated} notification(s) marked as read."})


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


# ── Live streaming ────────────────────────────────────────────────────────────

class StartLiveStreamView(APIView):
    """Creator starts a live stream. Returns the Jitsi room name."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        profile = get_object_or_404(CreatorProfile, user=request.user)
        # End any previously active stream for this creator
        LiveStream.objects.filter(creator=profile, is_live=True).update(
            is_live=False, ended_at=timezone.now()
        )
        title = request.data.get('title', 'Live Stream')
        import uuid
        room_name = f"{profile.slug}-{uuid.uuid4().hex[:8]}"
        stream = LiveStream.objects.create(creator=profile, room_name=room_name, title=title)
        return Response(LiveStreamSerializer(stream).data, status=status.HTTP_201_CREATED)


class EndLiveStreamView(APIView):
    """Creator ends their active live stream."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        profile = get_object_or_404(CreatorProfile, user=request.user)
        updated = LiveStream.objects.filter(creator=profile, is_live=True).update(
            is_live=False, ended_at=timezone.now()
        )
        if updated == 0:
            return Response({'detail': 'No active stream.'}, status=status.HTTP_404_NOT_FOUND)
        return Response({'detail': 'Stream ended.'})


class GetLiveStreamView(APIView):
    """Public: returns the active live stream for a creator slug, or 404."""
    permission_classes = [permissions.AllowAny]

    def get(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream is None:
            return Response({'detail': 'No active stream.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(LiveStreamSerializer(stream).data)


class LiveStreamCommentsView(APIView):
    """
    GET  /api/creators/<slug>/live/comments/?since=<id>  — poll for new comments
    POST /api/creators/<slug>/live/comments/             — post a comment
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream is None:
            return Response([])
        since = request.query_params.get('since', 0)
        try:
            since = int(since)
        except (ValueError, TypeError):
            since = 0
        comments = LiveStreamComment.objects.filter(
            stream=stream, id__gt=since
        ).order_by('created_at')[:50]
        return Response(LiveStreamCommentSerializer(comments, many=True).data)

    def post(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream is None:
            return Response({'error': 'No active stream.'}, status=status.HTTP_404_NOT_FOUND)
        data = request.data.copy()
        # Auto-detect creator: authenticated user who owns this profile
        is_creator = (
            request.user.is_authenticated
            and hasattr(request.user, 'creator_profile')
            and request.user.creator_profile.slug == slug
        )
        serializer = LiveStreamCommentSerializer(data=data)
        if serializer.is_valid():
            serializer.save(creator=profile, stream=stream, is_creator=is_creator)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LiveTopTippersView(APIView):
    """GET /api/creators/<slug>/live/top-tippers/ — top 3 tippers for the current live session."""
    permission_classes = [permissions.AllowAny]

    def get(self, request, slug):
        from django.db.models import Sum
        from apps.payments.models import Tip
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream is None:
            return Response([])
        top = (
            Tip.objects.filter(
                creator=profile,
                status='completed',
                created_at__gte=stream.started_at,
            )
            .values('tipper_name', 'tipper_email')
            .annotate(total=Sum('amount'))
            .order_by('-total')[:3]
        )
        return Response([
            {'name': t['tipper_name'] or t['tipper_email'].split('@')[0], 'total': str(t['total'])}
            for t in top
        ])


class LiveStreamGoalsView(APIView):
    """
    GET  /api/creators/<slug>/live/goals/  — active goal (public)
    POST /api/creators/<slug>/live/goals/  — set a new goal (creator only)
    DELETE /api/creators/<slug>/live/goals/<pk>/ — deactivate goal (creator only)
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream is None:
            return Response(None)
        goal = LiveStreamGoal.objects.filter(stream=stream, is_active=True).first()
        if not goal:
            return Response(None)
        return Response(LiveStreamGoalSerializer(goal).data)

    def post(self, request, slug):
        if not request.user.is_authenticated:
            return Response({'error': 'Authentication required'}, status=401)
        profile = get_object_or_404(CreatorProfile, slug=slug)
        if not hasattr(request.user, 'creator_profile') or request.user.creator_profile.slug != slug:
            return Response({'error': 'Forbidden'}, status=403)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream is None:
            return Response({'error': 'No active stream.'}, status=404)
        # Deactivate existing active goals for this stream
        LiveStreamGoal.objects.filter(stream=stream, is_active=True).update(is_active=False)
        serializer = LiveStreamGoalSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(creator=profile, stream=stream)
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    def delete(self, request, slug):
        if not request.user.is_authenticated:
            return Response({'error': 'Authentication required'}, status=401)
        profile = get_object_or_404(CreatorProfile, slug=slug)
        if not hasattr(request.user, 'creator_profile') or request.user.creator_profile.slug != slug:
            return Response({'error': 'Forbidden'}, status=403)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream:
            LiveStreamGoal.objects.filter(stream=stream, is_active=True).update(is_active=False)
        return Response(status=204)


class HasTippedView(APIView):
    """Authenticated: returns whether the logged-in user has tipped this creator."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, slug):
        creator = get_object_or_404(CreatorProfile, slug=slug)
        has_tipped = Tip.objects.filter(
            creator=creator,
            tipper_email__iexact=request.user.email,
            status=Tip.Status.COMPLETED,
        ).exists()
        return Response({'has_tipped': has_tipped})


class AllLiveStreamsView(APIView):
    """Public: list all currently live streams across all creators."""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        streams = LiveStream.objects.filter(is_live=True).select_related('creator', 'creator__user')
        return Response(LiveStreamWithCreatorSerializer(streams, many=True, context={'request': request}).data)


class GlobalFeedView(generics.ListAPIView):
    """Public: 50 most recent published posts across all creators."""
    serializer_class = CreatorPostFeedSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return CreatorPost.objects.filter(
            is_published=True
        ).select_related('creator').order_by('-created_at')[:50]


# ─── Advanced live-stream views ───────────────────────────────────────────────

class JoinLiveStreamView(APIView):
    """POST: fan joins stream → increments viewer_count. Returns viewer_count."""
    permission_classes = [permissions.AllowAny]

    def post(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if not stream:
            return Response({'error': 'No active stream.'}, status=404)
        LiveStream.objects.filter(pk=stream.pk).update(
            viewer_count=models.F('viewer_count') + 1
        )
        stream.refresh_from_db()
        return Response({'viewer_count': stream.viewer_count})


class LiveStreamStatsView(APIView):
    """GET: live stream stats — viewer count, total tips this session, comment count."""
    permission_classes = [permissions.AllowAny]

    def get(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if not stream:
            return Response({'viewer_count': 0, 'total_tips': '0.00', 'comment_count': 0})
        total_tips = (
            Tip.objects.filter(creator=profile, status='completed',
                               created_at__gte=stream.started_at)
            .aggregate(total=Sum('amount'))['total'] or 0
        )
        comment_count = LiveStreamComment.objects.filter(
            stream=stream, is_deleted=False
        ).count()
        return Response({
            'viewer_count': stream.viewer_count,
            'total_tips': str(total_tips),
            'comment_count': comment_count,
        })


class LiveStreamReactionView(APIView):
    """
    GET  <slug>/live/reactions/ — reaction counts for the last 10 seconds
    POST <slug>/live/reactions/ — send a reaction {"reaction_type": "heart"}
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if not stream:
            return Response({})
        since = timezone.now() - datetime.timedelta(seconds=10)
        counts = {}
        for r in LiveStreamReaction.objects.filter(stream=stream, created_at__gte=since):
            counts[r.reaction_type] = counts.get(r.reaction_type, 0) + 1
        return Response(counts)

    def post(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if not stream:
            return Response({'error': 'No active stream.'}, status=404)
        reaction_type = request.data.get('reaction_type', 'heart')
        valid = [c[0] for c in LiveStreamReaction.TYPES]
        if reaction_type not in valid:
            return Response({'error': 'Invalid reaction type.'}, status=400)
        LiveStreamReaction.objects.create(stream=stream, reaction_type=reaction_type)
        return Response({'ok': True}, status=201)


class PinCommentView(APIView):
    """POST: toggle pin on a comment (creator only)."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, slug, pk):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        if not hasattr(request.user, 'creator_profile') or request.user.creator_profile.slug != slug:
            return Response({'error': 'Forbidden'}, status=403)
        comment = get_object_or_404(LiveStreamComment, pk=pk, creator=profile)
        # Unpin all others, then toggle this one
        if not comment.is_pinned:
            LiveStreamComment.objects.filter(creator=profile, is_pinned=True).update(is_pinned=False)
        comment.is_pinned = not comment.is_pinned
        comment.save(update_fields=['is_pinned'])
        return Response({'is_pinned': comment.is_pinned})


class DeleteCommentView(APIView):
    """DELETE: soft-delete a comment (creator only)."""
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, slug, pk):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        if not hasattr(request.user, 'creator_profile') or request.user.creator_profile.slug != slug:
            return Response({'error': 'Forbidden'}, status=403)
        comment = get_object_or_404(LiveStreamComment, pk=pk, creator=profile)
        comment.is_deleted = True
        comment.save(update_fields=['is_deleted'])
        return Response(status=204)


class LiveStreamPollView(APIView):
    """
    GET  <slug>/live/poll/ — active poll + options + vote counts
    POST <slug>/live/poll/ — creator creates a poll {"question": "...", "options": ["A","B","C"]}
    DELETE <slug>/live/poll/ — creator closes active poll
    """
    permission_classes = [permissions.AllowAny]

    def _is_creator(self, request, slug):
        return (
            request.user.is_authenticated
            and hasattr(request.user, 'creator_profile')
            and request.user.creator_profile.slug == slug
        )

    def get(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if not stream:
            return Response(None)
        poll = LiveStreamPoll.objects.filter(stream=stream, is_active=True).first()
        if not poll:
            return Response(None)
        return Response(LiveStreamPollSerializer(poll).data)

    def post(self, request, slug):
        if not self._is_creator(request, slug):
            return Response({'error': 'Forbidden'}, status=403)
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if not stream:
            return Response({'error': 'No active stream.'}, status=404)
        question = request.data.get('question', '').strip()
        options = [o.strip() for o in request.data.get('options', []) if str(o).strip()]
        if not question or len(options) < 2:
            return Response({'error': 'question and at least 2 options are required.'}, status=400)
        # Deactivate any existing poll
        LiveStreamPoll.objects.filter(stream=stream, is_active=True).update(is_active=False)
        poll = LiveStreamPoll.objects.create(stream=stream, question=question)
        for text in options:
            LiveStreamPollOption.objects.create(poll=poll, text=text)
        return Response(LiveStreamPollSerializer(poll).data, status=201)

    def delete(self, request, slug):
        if not self._is_creator(request, slug):
            return Response({'error': 'Forbidden'}, status=403)
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if stream:
            LiveStreamPoll.objects.filter(stream=stream, is_active=True).update(is_active=False)
        return Response(status=204)


class VotePollView(APIView):
    """POST <slug>/live/poll/vote/ — fan votes {"option_id": 3}."""
    permission_classes = [permissions.AllowAny]

    def post(self, request, slug):
        profile = get_object_or_404(CreatorProfile, slug=slug)
        stream = LiveStream.objects.filter(creator=profile, is_live=True).first()
        if not stream:
            return Response({'error': 'No active stream.'}, status=404)
        poll = LiveStreamPoll.objects.filter(stream=stream, is_active=True).first()
        if not poll:
            return Response({'error': 'No active poll.'}, status=404)
        option_id = request.data.get('option_id')
        option = get_object_or_404(LiveStreamPollOption, pk=option_id, poll=poll)
        LiveStreamPollOption.objects.filter(pk=option.pk).update(
            vote_count=models.F('vote_count') + 1
        )
        poll.refresh_from_db()
        return Response(LiveStreamPollSerializer(poll).data)
