from django.db.models import Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.blog.models import BlogPost
from apps.creators.models import CreatorKycDocument, CreatorProfile
from apps.enterprise.models import Enterprise
from apps.tips.models import Tip
from apps.users.models import User

from .permissions import IsAdminUser
from .serializers import (
    AdminBlogSerializer,
    AdminCreatorSerializer,
    AdminEnterpriseSerializer,
    AdminTipSerializer,
    AdminUserSerializer,
)


# ── Platform stats ─────────────────────────────────────────────────────────────

class AdminStatsView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        today = timezone.now().date()
        month_start = today.replace(day=1)
        completed = Tip.objects.filter(status="completed")
        return Response({
            "total_users": User.objects.count(),
            "total_creators": User.objects.filter(role="creator").count(),
            "total_fans": User.objects.filter(role="fan").count(),
            "total_enterprises": User.objects.filter(role="enterprise").count(),
            "total_tips": completed.count(),
            "total_volume": float(completed.aggregate(v=Sum("amount"))["v"] or 0),
            "tips_today": completed.filter(created_at__date=today).count(),
            "tips_this_month": completed.filter(created_at__date__gte=month_start).count(),
            "pending_kyc": CreatorProfile.objects.filter(kyc_status="pending").count(),
            "pending_enterprises": Enterprise.objects.filter(
                approval_status=Enterprise.ApprovalStatus.PENDING).count(),
            "published_blogs": BlogPost.objects.filter(is_published=True).count(),
        })


# ── Users ──────────────────────────────────────────────────────────────────────

class AdminUserListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = User.objects.all().order_by("-date_joined")
        role = request.query_params.get("role")
        search = request.query_params.get("search", "").strip()
        if role:
            qs = qs.filter(role=role)
        if search:
            qs = qs.filter(email__icontains=search)
        return Response(AdminUserSerializer(qs[:200], many=True).data)


class AdminUserDetailView(APIView):
    permission_classes = [IsAdminUser]

    def patch(self, request, pk):
        user = get_object_or_404(User, pk=pk)
        # Allow updating role and is_active only
        allowed = {k: v for k, v in request.data.items() if k in ("role", "is_active")}
        for field, value in allowed.items():
            setattr(user, field, value)
        user.save(update_fields=list(allowed.keys()))
        return Response(AdminUserSerializer(user).data)


# ── Tips ───────────────────────────────────────────────────────────────────────

class AdminTipListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = (
            Tip.objects.select_related("creator", "tipper")
            .order_by("-created_at")
        )
        tip_status = request.query_params.get("status")
        search = request.query_params.get("search", "").strip()
        if tip_status:
            qs = qs.filter(status=tip_status)
        if search:
            qs = qs.filter(tipper_email__icontains=search) | qs.filter(
                creator__display_name__icontains=search
            )
        return Response(AdminTipSerializer(qs[:500], many=True).data)


# ── Creators ───────────────────────────────────────────────────────────────────

class AdminCreatorListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = (
            CreatorProfile.objects.select_related("user")
            .prefetch_related("kyc_documents")
            .order_by("-created_at")
        )
        kyc = request.query_params.get("kyc_status")
        search = request.query_params.get("search", "").strip()
        if kyc:
            qs = qs.filter(kyc_status=kyc)
        if search:
            qs = qs.filter(display_name__icontains=search) | qs.filter(
                user__email__icontains=search
            )
        return Response(AdminCreatorSerializer(qs[:200], many=True).data)


class AdminKycApproveView(APIView):
    """Approve all KYC documents for a creator and set kyc_status=approved."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        profile = get_object_or_404(CreatorProfile, pk=pk)
        profile.kyc_status = CreatorProfile.KycStatus.APPROVED
        profile.kyc_decline_reason = ""
        profile.save(update_fields=["kyc_status", "kyc_decline_reason"])
        CreatorKycDocument.objects.filter(
            creator=profile, status=CreatorKycDocument.DocStatus.PENDING
        ).update(status=CreatorKycDocument.DocStatus.APPROVED)
        return Response({"detail": "KYC approved."})


class AdminKycDeclineView(APIView):
    """Decline KYC for a creator with an optional reason."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        profile = get_object_or_404(CreatorProfile, pk=pk)
        reason = request.data.get("reason", "")
        profile.kyc_status = CreatorProfile.KycStatus.DECLINED
        profile.kyc_decline_reason = reason
        profile.save(update_fields=["kyc_status", "kyc_decline_reason"])
        return Response({"detail": "KYC declined."})


# ── Enterprises ────────────────────────────────────────────────────────────────

class AdminEnterpriseListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = (
            Enterprise.objects.select_related("user")
            .prefetch_related("documents")
            .order_by("-created_at")
        )
        approval = request.query_params.get("approval_status")
        if approval:
            qs = qs.filter(approval_status=approval)
        return Response(AdminEnterpriseSerializer(qs, many=True).data)


class AdminEnterpriseApproveView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        enterprise = get_object_or_404(Enterprise, pk=pk)
        enterprise.approval_status = Enterprise.ApprovalStatus.APPROVED
        enterprise.rejection_reason = ""
        enterprise.save(update_fields=["approval_status", "rejection_reason"])
        return Response({"detail": "Enterprise approved."})


class AdminEnterpriseRejectView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        enterprise = get_object_or_404(Enterprise, pk=pk)
        reason = request.data.get("reason", "")
        enterprise.approval_status = Enterprise.ApprovalStatus.REJECTED
        enterprise.rejection_reason = reason
        enterprise.save(update_fields=["approval_status", "rejection_reason"])
        return Response({"detail": "Enterprise rejected."})


# ── Blog (full CRUD for admin) ─────────────────────────────────────────────────

class AdminBlogListCreateView(APIView):
    permission_classes = [IsAdminUser]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        posts = BlogPost.objects.all()
        return Response(AdminBlogSerializer(posts, many=True).data)

    def post(self, request):
        serializer = AdminBlogSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AdminBlogDetailView(APIView):
    permission_classes = [IsAdminUser]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request, slug):
        post = get_object_or_404(BlogPost, slug=slug)
        return Response(AdminBlogSerializer(post).data)

    def patch(self, request, slug):
        post = get_object_or_404(BlogPost, slug=slug)
        serializer = AdminBlogSerializer(post, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, slug):
        post = get_object_or_404(BlogPost, slug=slug)
        post.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
