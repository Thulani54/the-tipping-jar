from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .emails import send_contact_confirmation, send_contact_to_support, send_dispute_confirmation
from .models import Dispute
from .serializers import ContactSerializer, DisputeCreateSerializer, DisputeDetailSerializer


class ContactView(APIView):
    """
    POST /api/support/contact/
    Anyone can submit a contact form — no auth required.
    Sends notification to support@ and acknowledgement to the submitter.
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ContactSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        contact = serializer.save()

        send_contact_to_support(contact)
        send_contact_confirmation(contact)

        return Response(
            {
                "message": "Your message has been received. We'll be in touch within 1–2 business days.",
                "id": contact.id,
            },
            status=status.HTTP_201_CREATED,
        )


class DisputeCreateView(APIView):
    """
    POST /api/support/disputes/
    Anyone can open a dispute. Authenticated users have their FK set automatically.
    Sends a tracking link to the submitter's email.
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = DisputeCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        dispute = serializer.save(
            user=request.user if request.user.is_authenticated else None
        )

        send_dispute_confirmation(dispute)

        return Response(
            {
                "message": (
                    f"Dispute {dispute.reference} has been filed. "
                    "Check your email for a tracking link."
                ),
                "reference": dispute.reference,
                "token": str(dispute.token),
            },
            status=status.HTTP_201_CREATED,
        )


class DisputeDetailView(generics.RetrieveAPIView):
    """
    GET /api/support/disputes/<token>/
    Public lookup by UUID token (sent in the confirmation email).
    """

    serializer_class = DisputeDetailSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = "token"

    def get_queryset(self):
        return Dispute.objects.all()
