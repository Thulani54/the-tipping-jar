from django.shortcuts import get_object_or_404
from rest_framework import permissions, status
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.creators.models import CreatorProfile
from apps.creators.serializers import CreatorProfileSerializer

from .models import Platform, PlatformDocument, PlatformUser
from .serializers import PlatformDocumentSerializer, PlatformSerializer, PlatformUserSerializer

# ── Helpers ───────────────────────────────────────────────────────────────────

def _get_platform_from_auth(request) -> Platform:
    """Return the Platform from request.auth (set by PlatformKeyAuthentication)."""
    return request.auth


# ── Public application ─────────────────────────────────────────────────────────

class PlatformApplyView(APIView):
    """POST /api/platform/apply/ — anyone can submit a platform application."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PlatformSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        owner = request.user if request.user.is_authenticated else None
        if owner is None:
            # Require auth to apply
            return Response(
                {"detail": "Authentication required to apply."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        platform = serializer.save(owner=owner)
        return Response(
            {"id": platform.id, "name": platform.name, "status": platform.approval_status},
            status=status.HTTP_201_CREATED,
        )


class PlatformDocumentUploadView(APIView):
    """POST /api/platform/apply/<pk>/documents/ — upload doc for pending application."""

    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser]

    def post(self, request, pk):
        platform = get_object_or_404(Platform, pk=pk, owner=request.user)

        doc_type = request.data.get("doc_type", "").strip()
        file_obj = request.FILES.get("file")

        if not doc_type:
            return Response({"detail": "doc_type is required."}, status=status.HTTP_400_BAD_REQUEST)
        if doc_type not in [c[0] for c in PlatformDocument.DocType.choices]:
            return Response({"detail": f"Invalid doc_type: {doc_type}."}, status=status.HTTP_400_BAD_REQUEST)
        if not file_obj:
            return Response({"detail": "file is required."}, status=status.HTTP_400_BAD_REQUEST)

        # Replace existing document of same type
        PlatformDocument.objects.filter(platform=platform, doc_type=doc_type).delete()
        doc = PlatformDocument.objects.create(platform=platform, doc_type=doc_type, file=file_obj)
        return Response(
            PlatformDocumentSerializer(doc, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


# ── Platform key authenticated views ──────────────────────────────────────────

class MyPlatformView(APIView):
    """GET /api/platform/me/ — info about this platform (requires X-Platform-Key)."""

    def get(self, request):
        if not isinstance(request.auth, Platform):
            return Response({"detail": "Platform key required."}, status=status.HTTP_403_FORBIDDEN)
        platform = _get_platform_from_auth(request)
        return Response(PlatformSerializer(platform, context={"request": request}).data)


class PlatformUserListCreateView(APIView):
    """
    GET /api/platform/users/ — list end-users on this platform.
    POST /api/platform/users/ — register a user on this platform.
    """

    def get(self, request):
        if not isinstance(request.auth, Platform):
            return Response({"detail": "Platform key required."}, status=status.HTTP_403_FORBIDDEN)
        platform = _get_platform_from_auth(request)
        qs = platform.platform_users.select_related("user").order_by("-created_at")
        return Response(PlatformUserSerializer(qs, many=True).data)

    def post(self, request):
        if not isinstance(request.auth, Platform):
            return Response({"detail": "Platform key required."}, status=status.HTTP_403_FORBIDDEN)
        platform = _get_platform_from_auth(request)

        user_id = request.data.get("user_id")
        email = request.data.get("email", "").strip()
        external_id = request.data.get("external_id", "").strip()

        from django.contrib.auth import get_user_model
        User = get_user_model()

        # Lookup by user_id or email
        user = None
        if user_id:
            user = get_object_or_404(User, pk=user_id)
        elif email:
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                return Response({"detail": "No user with that email."}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({"detail": "user_id or email is required."}, status=status.HTTP_400_BAD_REQUEST)

        pu, created = PlatformUser.objects.get_or_create(
            platform=platform, user=user,
            defaults={"external_id": external_id},
        )
        if not created and external_id:
            pu.external_id = external_id
            pu.save(update_fields=["external_id"])

        return Response(
            PlatformUserSerializer(pu).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class PlatformCreatorListView(APIView):
    """GET /api/platform/creators/ — public creator list (no platform scoping needed)."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        qs = CreatorProfile.objects.filter(is_active=True).select_related("user").order_by("-total_tips")[:50]
        return Response(CreatorProfileSerializer(qs, many=True, context={"request": request}).data)


class PlatformTipView(APIView):
    """POST /api/platform/tips/ — initiate a tip on behalf of a platform user."""

    def post(self, request):
        if not isinstance(request.auth, Platform):
            return Response({"detail": "Platform key required."}, status=status.HTTP_403_FORBIDDEN)

        # Delegate to the standard tip initiation endpoint logic
        from apps.tips.views import InitiateTipView
        return InitiateTipView.as_view()(request._request)


# ── Admin approval ─────────────────────────────────────────────────────────────

class AdminPlatformApproveView(APIView):
    """POST /api/admin/platforms/<pk>/approve/ — generate and return raw platform key (once)."""

    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        platform = get_object_or_404(Platform, pk=pk)

        raw_key, key_hash, key_prefix = Platform.generate_key()
        platform.platform_key_hash = key_hash
        platform.platform_key_prefix = key_prefix
        platform.approval_status = Platform.ApprovalStatus.APPROVED
        platform.rejection_reason = ""
        platform.save(update_fields=["platform_key_hash", "platform_key_prefix", "approval_status", "rejection_reason"])

        return Response({
            "detail": "Platform approved.",
            "approval_status": platform.approval_status,
            "platform_key": raw_key,
            "platform_key_prefix": key_prefix,
            "warning": "Store the platform_key securely — it is shown only once.",
        })


class AdminPlatformRejectView(APIView):
    """POST /api/admin/platforms/<pk>/reject/ — reject a platform application."""

    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        platform = get_object_or_404(Platform, pk=pk)
        reason = request.data.get("reason", "").strip()
        if not reason:
            return Response({"detail": "reason is required."}, status=status.HTTP_400_BAD_REQUEST)
        platform.approval_status = Platform.ApprovalStatus.REJECTED
        platform.rejection_reason = reason
        platform.save(update_fields=["approval_status", "rejection_reason"])
        return Response({"detail": "Platform rejected.", "approval_status": platform.approval_status})
