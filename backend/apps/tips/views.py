from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.creators.models import CreatorProfile
from .models import Tip
from .serializers import TipSerializer, CreateTipSerializer
import stripe
from django.conf import settings

stripe.api_key = settings.STRIPE_SECRET_KEY


class CreatorTipsView(generics.ListAPIView):
    """Public feed of completed tips for a creator."""

    serializer_class = TipSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        slug = self.kwargs["slug"]
        return Tip.objects.filter(creator__slug=slug, status=Tip.Status.COMPLETED)


class InitiateTipView(APIView):
    """Create a Stripe PaymentIntent and return client_secret to the Flutter app."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = CreateTipSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            creator = CreatorProfile.objects.get(slug=data["creator_slug"], is_active=True)
        except CreatorProfile.DoesNotExist:
            return Response({"detail": "Creator not found."}, status=status.HTTP_404_NOT_FOUND)

        amount_cents = int(data["amount"] * 100)

        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency="usd",
            metadata={
                "creator_id": creator.id,
                "tipper_name": data.get("tipper_name", "Anonymous"),
                "message": data.get("message", ""),
            },
        )

        # Create a pending Tip record
        Tip.objects.create(
            creator=creator,
            tipper=request.user if request.user.is_authenticated else None,
            tipper_name=data.get("tipper_name", "Anonymous"),
            amount=data["amount"],
            message=data.get("message", ""),
            stripe_payment_intent_id=intent.id,
        )

        return Response({"client_secret": intent.client_secret})
