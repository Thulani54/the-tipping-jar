import datetime
from decimal import Decimal

from django.conf import settings
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.creators.models import CreatorProfile, Jar
from apps.payments import paystack as ps
from apps.support.emails import send_tip_thank_you

from .models import Pledge, Tip, TipStreak
from .serializers import CreateTipSerializer, PledgeSerializer, TipSerializer, TipStreakSerializer


class CreatorTipsView(generics.ListAPIView):
    """Public feed of completed tips for a creator (by slug)."""

    serializer_class = TipSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        slug = self.kwargs["slug"]
        return Tip.objects.filter(creator__slug=slug, status=Tip.Status.COMPLETED)


class MyTipsView(generics.ListAPIView):
    """Authenticated creator's own tip history (tips received)."""

    serializer_class = TipSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CreatorProfile.objects.get(user=self.request.user)
            return profile.tips.filter(status=Tip.Status.COMPLETED).order_by("-created_at")
        except CreatorProfile.DoesNotExist:
            return Tip.objects.none()


class FanTipsView(generics.ListAPIView):
    """Authenticated fan's tips sent history."""

    serializer_class = TipSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Tip.objects.filter(
            tipper=self.request.user, status=Tip.Status.COMPLETED
        ).order_by("-created_at")


class InitiateTipView(APIView):
    """
    Initiate a tip payment.

    Dev mode (no PAYSTACK_SECRET_KEY): creates a completed Tip immediately.
    Production: initialises a Paystack transaction and returns authorization_url.

    Fee structure (default):
        - 3% platform fee  → TippingJar master account
        - 3% service fee   → deducted from creator's subaccount share by Paystack
        - Creator receives: ~94% of the tip amount
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = CreateTipSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        # ── Resolve creator ───────────────────────────────────────────
        try:
            creator = CreatorProfile.objects.get(
                slug=data["creator_slug"], is_active=True
            )
        except CreatorProfile.DoesNotExist:
            return Response(
                {"detail": "Creator not found."}, status=status.HTTP_404_NOT_FOUND
            )

        # ── Resolve optional jar ──────────────────────────────────────
        jar = None
        jar_id = data.get("jar_id")
        if jar_id:
            try:
                jar = Jar.objects.get(id=jar_id, creator=creator, is_active=True)
            except Jar.DoesNotExist:
                return Response(
                    {"detail": "Jar not found."}, status=status.HTTP_404_NOT_FOUND
                )

        amount = float(data["amount"])
        fees = ps.calculate_fees(amount)

        # ── Dev mode: no Paystack key configured ──────────────────────
        if not settings.PAYSTACK_SECRET_KEY:
            tip = Tip.objects.create(
                creator=creator,
                jar=jar,
                tipper=request.user if request.user.is_authenticated else None,
                tipper_name=data.get("tipper_name", "Anonymous"),
                tipper_email=data.get("tipper_email", ""),
                amount=data["amount"],
                message=data.get("message", ""),
                status=Tip.Status.COMPLETED,
                platform_fee=Decimal(str(fees["platform_fee"])),
                service_fee=Decimal(str(fees["service_fee"])),
                creator_net=Decimal(str(fees["creator_net"])),
            )
            send_tip_thank_you(tip)
            return Response(
                {
                    "dev_mode": True,
                    "tip_id": tip.id,
                    "amount": str(tip.amount),
                    "creator_name": creator.display_name,
                    "platform_fee": str(tip.platform_fee),
                    "service_fee": str(tip.service_fee),
                    "creator_net": str(tip.creator_net),
                },
                status=status.HTTP_201_CREATED,
            )

        # ── Production: Paystack transaction ──────────────────────────
        tipper_email = data.get("tipper_email") or "anonymous@tippingjar.co.za"

        # Create pending tip first so we have an ID for the reference
        tip = Tip.objects.create(
            creator=creator,
            jar=jar,
            tipper=request.user if request.user.is_authenticated else None,
            tipper_name=data.get("tipper_name", "Anonymous"),
            tipper_email=data.get("tipper_email", ""),
            amount=data["amount"],
            message=data.get("message", ""),
            status=Tip.Status.PENDING,
            platform_fee=Decimal(str(fees["platform_fee"])),
            service_fee=Decimal(str(fees["service_fee"])),
            creator_net=Decimal(str(fees["creator_net"])),
        )

        reference = ps.generate_reference(tip.id)
        tip.paystack_reference = reference
        tip.save(update_fields=["paystack_reference"])

        callback_url = f"{settings.SITE_URL}/payment/callback?ref={reference}"

        try:
            tx = ps.initialize_transaction(
                email=tipper_email,
                amount_zar=amount,
                reference=reference,
                subaccount_code=creator.paystack_subaccount_code or None,
                callback_url=callback_url,
                metadata={
                    "tip_id": tip.id,
                    "creator_slug": creator.slug,
                    "tipper_name": tip.tipper_name,
                    "jar_id": jar.id if jar else None,
                },
            )
        except RuntimeError as exc:
            # Clean up the pending tip if Paystack fails
            tip.delete()
            return Response(
                {"detail": str(exc)}, status=status.HTTP_502_BAD_GATEWAY
            )

        return Response(
            {
                "tip_id": tip.id,
                "reference": reference,
                "authorization_url": tx["authorization_url"],
                "access_code": tx.get("access_code", ""),
                "amount": str(tip.amount),
                "platform_fee": str(tip.platform_fee),
                "service_fee": str(tip.service_fee),
                "creator_net": str(tip.creator_net),
                "creator_name": creator.display_name,
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyTipView(APIView):
    """
    Verify a tip's payment status via Paystack.

    GET /api/tips/verify/<reference>/

    - Checks Paystack's verify endpoint
    - Updates tip status if payment succeeded or failed
    - Returns current tip status
    """

    permission_classes = [permissions.AllowAny]

    def get(self, request, reference):
        tip = get_object_or_404(Tip, paystack_reference=reference)

        creator_slug = tip.creator.slug

        # Already resolved — no need to call Paystack again
        if tip.status in (Tip.Status.COMPLETED, Tip.Status.FAILED, Tip.Status.REFUNDED):
            return Response({
                "status": tip.status,
                "tip_id": tip.id,
                "amount": str(tip.amount),
                "creator_net": str(tip.creator_net),
                "creator_slug": creator_slug,
            })

        if not settings.PAYSTACK_SECRET_KEY:
            # Dev mode — just return current status
            return Response({"status": tip.status, "tip_id": tip.id, "creator_slug": creator_slug})

        try:
            tx_data = ps.verify_transaction(reference)
        except RuntimeError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_502_BAD_GATEWAY)

        paystack_status = tx_data.get("status", "")

        if paystack_status == "success":
            # Atomic update — only mark completed if still pending (avoids double-email with webhook)
            rows = Tip.objects.filter(pk=tip.pk, status=Tip.Status.PENDING).update(
                status=Tip.Status.COMPLETED
            )
            if rows:
                tip.refresh_from_db()
                send_tip_thank_you(tip)
            else:
                tip.refresh_from_db()
        elif paystack_status in ("failed", "abandoned"):
            # Never downgrade a tip that the webhook already marked as completed
            Tip.objects.filter(pk=tip.pk, status=Tip.Status.PENDING).update(
                status=Tip.Status.FAILED
            )
            tip.refresh_from_db()

        return Response({
            "status": tip.status,
            "tip_id": tip.id,
            "amount": str(tip.amount),
            "creator_net": str(tip.creator_net),
            "creator_slug": creator_slug,
            "paystack_status": paystack_status,
        })


# ── Pledge views ──────────────────────────────────────────────────────────────

class MyPledgeListCreateView(generics.ListCreateAPIView):
    """Fan: list own pledges (GET) or create a new pledge (POST)."""

    serializer_class = PledgeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Pledge.objects.filter(fan=self.request.user)

    def post(self, request, *args, **kwargs):
        creator_slug = request.data.get("creator_slug")
        if not creator_slug:
            return Response({"detail": "creator_slug required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            creator = CreatorProfile.objects.get(slug=creator_slug, is_active=True)
        except CreatorProfile.DoesNotExist:
            return Response({"detail": "Creator not found."}, status=status.HTTP_404_NOT_FOUND)

        amount = request.data.get("amount")
        tier_id = request.data.get("tier_id")
        fan_email = request.data.get("fan_email", "") or request.user.email
        fan_name = request.data.get("fan_name", "") or request.user.username

        tier = None
        if tier_id:
            from apps.creators.models import SupportTier
            try:
                tier = SupportTier.objects.get(id=tier_id, creator=creator, is_active=True)
                if not amount:
                    amount = tier.price
            except SupportTier.DoesNotExist:
                return Response({"detail": "Tier not found."}, status=status.HTTP_404_NOT_FOUND)

        if not amount:
            return Response({"detail": "amount required."}, status=status.HTTP_400_BAD_REQUEST)

        # Dev mode — create immediately as ACTIVE
        if not settings.PAYSTACK_SECRET_KEY:
            pledge = Pledge.objects.create(
                fan=request.user,
                fan_email=fan_email,
                fan_name=fan_name,
                creator=creator,
                tier=tier,
                amount=amount,
                status=Pledge.Status.ACTIVE,
                next_charge_date=datetime.date.today() + datetime.timedelta(days=30),
            )
            return Response(PledgeSerializer(pledge).data, status=status.HTTP_201_CREATED)

        # Production — initiate Paystack transaction for first charge
        pledge = Pledge.objects.create(
            fan=request.user,
            fan_email=fan_email,
            fan_name=fan_name,
            creator=creator,
            tier=tier,
            amount=amount,
            status=Pledge.Status.PAUSED,
            paystack_email=fan_email,
        )
        reference = ps.generate_reference(pledge.id)
        callback_url = f"{settings.SITE_URL}/payment/callback?ref={reference}&pledge=1"
        try:
            tx = ps.initialize_transaction(
                email=fan_email,
                amount_zar=float(amount),
                reference=reference,
                callback_url=callback_url,
                metadata={"pledge_id": pledge.id, "creator_slug": creator.slug},
            )
        except RuntimeError as exc:
            pledge.delete()
            return Response({"detail": str(exc)}, status=status.HTTP_502_BAD_GATEWAY)

        return Response({
            "pledge_id": pledge.id,
            "authorization_url": tx["authorization_url"],
            "reference": reference,
        }, status=status.HTTP_201_CREATED)


class PublicPledgeCreateView(APIView):
    """
    POST /api/tips/subscribe/
    Anonymous OR authenticated fans subscribe to a creator tier.
    fan_email is required for guest pledges; authenticated users default to their account email.
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from apps.creators.models import SupportTier  # noqa: PLC0415

        creator_slug = request.data.get("creator_slug")
        if not creator_slug:
            return Response({"detail": "creator_slug required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            creator = CreatorProfile.objects.get(slug=creator_slug, is_active=True)
        except CreatorProfile.DoesNotExist:
            return Response({"detail": "Creator not found."}, status=status.HTTP_404_NOT_FOUND)

        fan = request.user if request.user.is_authenticated else None
        fan_email = request.data.get("fan_email", "") or (fan.email if fan else "")
        fan_name = request.data.get("fan_name", "") or (fan.username if fan else "Anonymous")

        if not fan_email:
            return Response({"detail": "fan_email is required."}, status=status.HTTP_400_BAD_REQUEST)

        tier_id = request.data.get("tier_id")
        amount = request.data.get("amount")

        tier = None
        if tier_id:
            try:
                tier = SupportTier.objects.get(id=tier_id, creator=creator, is_active=True)
                if not amount:
                    amount = tier.price
            except SupportTier.DoesNotExist:
                return Response({"detail": "Tier not found."}, status=status.HTTP_404_NOT_FOUND)

        if not amount:
            return Response({"detail": "amount required."}, status=status.HTTP_400_BAD_REQUEST)

        # Dev mode — create pledge immediately as ACTIVE
        if not settings.PAYSTACK_SECRET_KEY:
            pledge = Pledge.objects.create(
                fan=fan,
                fan_email=fan_email,
                fan_name=fan_name,
                creator=creator,
                tier=tier,
                amount=amount,
                status=Pledge.Status.ACTIVE,
                next_charge_date=datetime.date.today() + datetime.timedelta(days=30),
            )
            return Response(PledgeSerializer(pledge).data, status=status.HTTP_201_CREATED)

        # Production — initiate Paystack transaction for first charge
        pledge = Pledge.objects.create(
            fan=fan,
            fan_email=fan_email,
            fan_name=fan_name,
            creator=creator,
            tier=tier,
            amount=amount,
            status=Pledge.Status.PAUSED,
            paystack_email=fan_email,
        )
        reference = ps.generate_reference(pledge.id)
        callback_url = f"{settings.SITE_URL}/payment/callback?ref={reference}&pledge=1"
        try:
            tx = ps.initialize_transaction(
                email=fan_email,
                amount_zar=float(amount),
                reference=reference,
                callback_url=callback_url,
                metadata={"pledge_id": pledge.id, "creator_slug": creator.slug},
            )
        except RuntimeError as exc:
            pledge.delete()
            return Response({"detail": str(exc)}, status=status.HTTP_502_BAD_GATEWAY)

        return Response({
            "pledge_id": pledge.id,
            "authorization_url": tx["authorization_url"],
            "reference": reference,
        }, status=status.HTTP_201_CREATED)


class MyPledgeDetailView(generics.UpdateAPIView):
    """Fan: pause or cancel own pledge."""

    serializer_class = PledgeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Pledge.objects.filter(fan=self.request.user)


class MyStreakListView(generics.ListAPIView):
    """Fan: list their own tip streaks."""

    serializer_class = TipStreakSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return TipStreak.objects.filter(fan=self.request.user).select_related("creator")
