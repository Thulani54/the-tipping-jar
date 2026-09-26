import logging
import threading

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Referral, ReferralCode
from .serializers import BankDetailsSerializer, ReferralCodeSerializer, ReferralSerializer

logger = logging.getLogger(__name__)


class MyReferralsView(APIView):
    """
    GET /api/referrals/me/
    Returns the caller's referral code + all referrals they've made.
    """

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        code_obj, _ = ReferralCode.objects.get_or_create(owner=request.user)
        referrals = Referral.objects.filter(referrer=request.user).select_related(
            "referred_user"
        )
        return Response(
            {
                "code": ReferralCodeSerializer(code_obj).data,
                "referrals": ReferralSerializer(referrals, many=True).data,
                "total_referrals": referrals.count(),
                "active_referrals": referrals.filter(
                    status=Referral.Status.ACTIVE
                ).count(),
            }
        )


class ValidateReferralCodeView(APIView):
    """
    GET /api/referrals/validate/<code>/
    Public — returns referrer display name if the code is valid.
    """

    permission_classes = [permissions.AllowAny]

    def get(self, request, code):
        try:
            code_obj = ReferralCode.objects.select_related("owner").get(
                code=code.upper().strip(), is_active=True
            )
        except ReferralCode.DoesNotExist:
            return Response(
                {"detail": "Invalid referral code."},
                status=status.HTTP_404_NOT_FOUND,
            )
        owner = code_obj.owner
        return Response(
            {
                "valid": True,
                "referrer_name": owner.get_full_name() or owner.username,
                "commission_rate": float(code_obj.commission_rate),
            }
        )


def _send_invite_email(referrer_name: str, referrer_code: str, email: str) -> None:
    try:
        send_mail(
            subject=f"{referrer_name} invites you to join TippingJar",
            message=(
                f"Hi,\n\n"
                f"{referrer_name} thinks you should start earning with TippingJar — "
                f"the creator tip platform where payouts reach your bank in 1–2 days.\n\n"
                f"Sign up using {referrer_name}'s referral code:\n\n"
                f"  Referral code: {referrer_code}\n"
                f"  Sign up: https://tippingjar.co.za/register?ref={referrer_code}\n\n"
                f"© TippingJar"
            ),
            from_email=settings.NO_REPLY_EMAIL,
            recipient_list=[email],
            fail_silently=True,
        )
    except Exception as exc:
        logger.error("Invite email failed for %s: %s", email, exc)


class InviteCreatorsView(APIView):
    """
    POST /api/referrals/invite/
    Body: { "emails": ["a@x.com", ...] }   (max 10)
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        emails = (request.data.get("emails") or [])[:10]
        user = request.user
        code_obj, _ = ReferralCode.objects.get_or_create(owner=user)
        referrer_name = user.get_full_name() or user.username

        sent, failed = [], []
        for email in emails:
            email = str(email).strip()
            if not email or "@" not in email:
                continue
            threading.Thread(
                target=_send_invite_email,
                args=(referrer_name, code_obj.code, email),
                daemon=True,
            ).start()
            sent.append(email)

        return Response({"sent": sent, "queued": len(sent)})


class SubmitBankDetailsView(APIView):
    """
    POST /api/referrals/<pk>/bank-details/
    Referrer submits bank account details so commission can be paid out.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            referral = Referral.objects.get(pk=pk, referrer=request.user)
        except Referral.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = BankDetailsSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        referral.bank_name = data["bank_name"]
        referral.bank_account_name = data["bank_account_name"]
        referral.bank_account_number = data["bank_account_number"]
        referral.bank_details_submitted_at = timezone.now()
        if referral.status == Referral.Status.PENDING:
            referral.status = Referral.Status.ACTIVE
        referral.save(
            update_fields=[
                "bank_name",
                "bank_account_name",
                "bank_account_number",
                "bank_details_submitted_at",
                "status",
            ]
        )
        return Response(
            {"detail": "Bank details saved. You will receive commission payments within the agreed window."}
        )
