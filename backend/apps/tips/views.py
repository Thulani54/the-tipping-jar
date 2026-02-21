from decimal import Decimal

from django.conf import settings
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.creators.models import CreatorProfile, Jar
from apps.payments import paystack as ps
from .models import Tip
from .serializers import TipSerializer, CreateTipSerializer


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
                amount=data["amount"],
                message=data.get("message", ""),
                status=Tip.Status.COMPLETED,
                platform_fee=Decimal(str(fees["platform_fee"])),
                service_fee=Decimal(str(fees["service_fee"])),
                creator_net=Decimal(str(fees["creator_net"])),
            )
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

        # Already resolved — no need to call Paystack again
        if tip.status in (Tip.Status.COMPLETED, Tip.Status.FAILED, Tip.Status.REFUNDED):
            return Response({
                "status": tip.status,
                "tip_id": tip.id,
                "amount": str(tip.amount),
                "creator_net": str(tip.creator_net),
            })

        if not settings.PAYSTACK_SECRET_KEY:
            # Dev mode — just return current status
            return Response({"status": tip.status, "tip_id": tip.id})

        try:
            tx_data = ps.verify_transaction(reference)
        except RuntimeError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_502_BAD_GATEWAY)

        paystack_status = tx_data.get("status", "")

        if paystack_status == "success":
            tip.status = Tip.Status.COMPLETED
            tip.save(update_fields=["status"])
        elif paystack_status in ("failed", "abandoned"):
            tip.status = Tip.Status.FAILED
            tip.save(update_fields=["status"])

        return Response({
            "status": tip.status,
            "tip_id": tip.id,
            "amount": str(tip.amount),
            "creator_net": str(tip.creator_net),
            "paystack_status": paystack_status,
        })
