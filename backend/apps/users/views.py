import logging

from django.conf import settings
from django.core.mail import send_mail
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.support.sms import send_otp_via_sms

logger = logging.getLogger(__name__)

from .models import OTP, ApiKey, User
from .serializers import ApiKeySerializer, RegisterSerializer, UserSerializer


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


# ── OTP management ─────────────────────────────────────────────────────────────

class RegistrationVerifyRequestView(APIView):
    """
    POST /api/users/verify-registration/
    Body: { "method": "email" | "sms" }  (optional, defaults to "email")

    Sends a 6-digit OTP for new-user email/phone verification.
    Unlike the 2FA OTP flow, this does NOT check two_fa_enabled — it is
    called once immediately after registration to verify the account.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        method = request.data.get("method", "email")

        if method == OTP.Method.SMS and not user.phone_number:
            return Response(
                {"detail": "No phone number on file. Use email verification instead."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp_obj, raw_code = OTP.generate_for(user, method=method)

        if method == OTP.Method.SMS:
            result = send_otp_via_sms(user.phone_number, raw_code)
            if not result["success"]:
                otp_obj.is_used = True
                otp_obj.save(update_fields=["is_used"])
                return Response(
                    {"detail": f"SMS delivery failed: {result.get('error')}"},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )
            channel_info = f"SMS to {user.phone_number[:4]}****"
        else:
            try:
                send_mail(
                    subject="TippingJar — Verify your email",
                    message=(
                        f"Welcome to TippingJar!\n\n"
                        f"Your verification code is: {raw_code}\n\n"
                        f"Valid for 10 minutes. If you didn't create this account, ignore this email."
                    ),
                    from_email=settings.NO_REPLY_EMAIL,
                    recipient_list=[user.email],
                    fail_silently=False,
                )
            except Exception as exc:
                logger.error("Registration OTP email failed for %s: %s", user.email, exc)
                otp_obj.is_used = True
                otp_obj.save(update_fields=["is_used"])
                return Response(
                    {"detail": "Could not send verification email. Please try again or skip for now."},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )
            channel_info = f"email to {user.email}"

        return Response(
            {"detail": f"Verification code sent via {channel_info}.", "method": method},
            status=status.HTTP_200_OK,
        )


class RegistrationVerifyConfirmView(APIView):
    """
    POST /api/users/verify-registration/confirm/
    Body: { "code": "123456" }

    Confirms the registration OTP. Does NOT check two_fa_enabled.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        code = (request.data.get("code") or "").strip()
        if not code:
            return Response({"detail": "code is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            otp_obj = OTP.objects.filter(user=request.user, is_used=False).latest("created_at")
        except OTP.DoesNotExist:
            return Response(
                {"detail": "No pending OTP. Request a new one."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not otp_obj.is_valid():
            return Response(
                {"detail": "Code expired. Request a new one."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if otp_obj.code != code:
            return Response({"detail": "Invalid code."}, status=status.HTTP_400_BAD_REQUEST)

        otp_obj.is_used = True
        otp_obj.save(update_fields=["is_used"])
        return Response({"detail": "Email verified successfully."}, status=status.HTTP_200_OK)


class OtpRequestView(APIView):
    """
    POST /api/users/otp/request/
    Body: { "method": "email" | "sms" }   (optional — uses user.otp_method if omitted)

    Generates a new OTP and delivers it via the requested channel.
    Requires authentication so we know who to OTP.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user

        # 2FA disabled — no OTP needed, treat as already verified
        if not user.two_fa_enabled:
            return Response({"detail": "2FA is disabled for this account.", "skipped": True},
                            status=status.HTTP_200_OK)

        method = request.data.get("method") or user.otp_method

        if method == OTP.Method.SMS and not user.phone_number:
            return Response(
                {"detail": "No phone number on file. Add one via PATCH /api/users/me/ first."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp_obj, raw_code = OTP.generate_for(user, method=method)

        if method == OTP.Method.SMS:
            result = send_otp_via_sms(user.phone_number, raw_code)
            if not result["success"]:
                otp_obj.is_used = True
                otp_obj.save(update_fields=["is_used"])
                return Response(
                    {"detail": f"SMS delivery failed: {result.get('error')}"},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )
            channel_info = f"SMS to {user.phone_number[:4]}****"
        else:
            # Email delivery
            try:
                send_mail(
                    subject="TippingJar — Your verification code",
                    message=f"Your TippingJar code is: {raw_code}\n\nValid for 10 minutes.",
                    from_email=settings.NO_REPLY_EMAIL,
                    recipient_list=[user.email],
                    fail_silently=False,
                )
            except Exception as exc:  # noqa: BLE001
                logger.error("OTP email delivery failed for %s: %s", user.email, exc)
                otp_obj.is_used = True
                otp_obj.save(update_fields=["is_used"])
                return Response(
                    {"detail": "Failed to send verification email. Please try again or contact support."},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )
            channel_info = f"email to {user.email}"

        return Response(
            {"detail": f"OTP sent via {channel_info}.", "method": method},
            status=status.HTTP_200_OK,
        )


class OtpVerifyView(APIView):
    """
    POST /api/users/otp/verify/
    Body: { "code": "123456" }

    Verifies the most recent valid OTP for the authenticated user.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # 2FA disabled — no OTP to verify
        if not request.user.two_fa_enabled:
            return Response({"detail": "OTP verified successfully."}, status=status.HTTP_200_OK)

        code = (request.data.get("code") or "").strip()
        if not code:
            return Response({"detail": "code is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            otp_obj = OTP.objects.filter(user=request.user, is_used=False).latest("created_at")
        except OTP.DoesNotExist:
            return Response({"detail": "No pending OTP. Request one first."}, status=status.HTTP_400_BAD_REQUEST)

        if not otp_obj.is_valid():
            return Response({"detail": "OTP has expired. Request a new one."}, status=status.HTTP_400_BAD_REQUEST)

        if otp_obj.code != code:
            return Response({"detail": "Invalid code."}, status=status.HTTP_400_BAD_REQUEST)

        otp_obj.is_used = True
        otp_obj.save(update_fields=["is_used"])
        return Response({"detail": "OTP verified successfully."}, status=status.HTTP_200_OK)


class OtpSwitchMethodView(APIView):
    """
    POST /api/users/otp/switch-method/
    Body: { "method": "email" | "sms" }

    Updates the user's preferred OTP delivery channel.
    Switching to SMS requires a phone number already on file.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        method = request.data.get("method", "").lower()
        if method not in (OTP.Method.EMAIL, OTP.Method.SMS):
            return Response(
                {"detail": "method must be 'email' or 'sms'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if method == OTP.Method.SMS and not request.user.phone_number:
            return Response(
                {"detail": "Add a phone number via PATCH /api/users/me/ before switching to SMS OTP."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        request.user.otp_method = method
        request.user.save(update_fields=["otp_method"])
        return Response({"detail": f"OTP method updated to {method}."}, status=status.HTTP_200_OK)


# ── API Key management ─────────────────────────────────────────────────────────

class ApiKeyListCreateView(APIView):
    """
    GET  /api/users/api-keys/  — list the caller's active API keys
    POST /api/users/api-keys/  — create a new key (raw key returned once)
    """

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        keys = ApiKey.objects.filter(user=request.user, is_active=True)
        return Response(ApiKeySerializer(keys, many=True).data)

    def post(self, request):
        name = request.data.get("name", "My Key") or "My Key"

        raw_key, key_hash, prefix = ApiKey.generate()

        key_obj = ApiKey.objects.create(
            user=request.user,
            name=name,
            key_hash=key_hash,
            prefix=prefix,
        )

        return Response(
            {
                "id": key_obj.id,
                "name": key_obj.name,
                "key": raw_key,
                "prefix": prefix,
                "is_active": True,
                "created_at": key_obj.created_at,
                "last_used_at": None,
            },
            status=status.HTTP_201_CREATED,
        )


class ApiKeyRevokeView(APIView):
    """
    DELETE /api/users/api-keys/<pk>/  — soft-delete (deactivate) an API key
    """

    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, pk):
        try:
            key = ApiKey.objects.get(pk=pk, user=request.user)
        except ApiKey.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        key.is_active = False
        key.save(update_fields=["is_active"])
        return Response({"detail": "API key revoked."}, status=status.HTTP_200_OK)
