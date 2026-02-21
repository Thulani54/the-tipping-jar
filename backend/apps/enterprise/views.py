from decimal import Decimal
from django.db.models import Sum, Count
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.creators.models import CreatorProfile
from apps.tips.models import Tip
from .models import Enterprise, EnterpriseMembership, FundDistribution, FundDistributionItem
from .serializers import (
    EnterpriseSerializer,
    EnterpriseMembershipSerializer,
    FundDistributionSerializer,
    FundDistributionItemSerializer,
    CreateFundDistributionSerializer,
)


# ── Permission helper ──────────────────────────────────────────────────────────

class IsEnterpriseAdmin(permissions.BasePermission):
    """Allows access only to users who own an Enterprise account."""

    def has_permission(self, request, view):
        return request.user.is_authenticated and hasattr(request.user, "enterprise")


def _get_enterprise(request) -> Enterprise:
    return request.user.enterprise


# ── Enterprise profile ─────────────────────────────────────────────────────────

class MyEnterpriseView(APIView):
    """GET / PATCH the authenticated enterprise's profile. POST to create one."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        try:
            enterprise = request.user.enterprise
        except Enterprise.DoesNotExist:
            return Response({"detail": "No enterprise account found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(EnterpriseSerializer(enterprise).data)

    def post(self, request):
        if hasattr(request.user, "enterprise"):
            return Response({"detail": "Enterprise already exists."}, status=status.HTTP_400_BAD_REQUEST)
        serializer = EnterpriseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(admin=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def patch(self, request):
        try:
            enterprise = request.user.enterprise
        except Enterprise.DoesNotExist:
            return Response({"detail": "No enterprise account found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = EnterpriseSerializer(enterprise, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


# ── Members ────────────────────────────────────────────────────────────────────

class EnterpriseMemberListView(APIView):
    """List all members or add a creator by slug."""

    permission_classes = [IsEnterpriseAdmin]

    def get(self, request):
        enterprise = _get_enterprise(request)
        members = enterprise.memberships.select_related(
            "creator", "creator__user"
        ).order_by("-joined_at")
        return Response(EnterpriseMembershipSerializer(members, many=True).data)

    def post(self, request):
        """Add a creator to this enterprise by creator slug."""
        enterprise = _get_enterprise(request)
        slug = request.data.get("creator_slug", "").strip()
        if not slug:
            return Response({"detail": "creator_slug is required."}, status=status.HTTP_400_BAD_REQUEST)

        creator = get_object_or_404(CreatorProfile, slug=slug, is_active=True)
        membership, created = EnterpriseMembership.objects.get_or_create(
            enterprise=enterprise, creator=creator
        )
        if not created and membership.is_active:
            return Response({"detail": "Creator is already a member."}, status=status.HTTP_400_BAD_REQUEST)
        if not created:
            membership.is_active = True
            membership.save(update_fields=["is_active"])
        return Response(
            EnterpriseMembershipSerializer(membership).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class EnterpriseMemberDetailView(APIView):
    """Deactivate (remove) a membership."""

    permission_classes = [IsEnterpriseAdmin]

    def delete(self, request, pk):
        enterprise = _get_enterprise(request)
        membership = get_object_or_404(EnterpriseMembership, pk=pk, enterprise=enterprise)
        membership.is_active = False
        membership.save(update_fields=["is_active"])
        return Response(status=status.HTTP_204_NO_CONTENT)


# ── Aggregate stats ────────────────────────────────────────────────────────────

class EnterpriseStatsView(APIView):
    """Aggregate tips / earnings across all managed creators."""

    permission_classes = [IsEnterpriseAdmin]

    def get(self, request):
        enterprise = _get_enterprise(request)
        creator_ids = enterprise.memberships.filter(is_active=True).values_list(
            "creator_id", flat=True
        )

        tips_qs = Tip.objects.filter(
            jar__creator_id__in=creator_ids, status="completed"
        )

        total_earned = float(tips_qs.aggregate(t=Sum("amount"))["t"] or 0)
        tip_count = tips_qs.count()
        creator_count = len(creator_ids)

        # Per-creator breakdown
        per_creator = list(
            tips_qs.values("jar__creator__slug", "jar__creator__display_name")
            .annotate(total=Sum("amount"), tips=Count("id"))
            .order_by("-total")
        )

        # Distributions summary
        distributions_qs = enterprise.distributions.all()
        total_distributed = float(
            distributions_qs.aggregate(t=Sum("total_amount"))["t"] or 0
        )
        distribution_count = distributions_qs.count()

        return Response({
            "creator_count": creator_count,
            "tip_count": tip_count,
            "total_earned": total_earned,
            "total_distributed": total_distributed,
            "distribution_count": distribution_count,
            "per_creator": [
                {
                    "slug": row["jar__creator__slug"],
                    "display_name": row["jar__creator__display_name"],
                    "total": float(row["total"]),
                    "tips": row["tips"],
                }
                for row in per_creator
            ],
        })


# ── Fund distributions ─────────────────────────────────────────────────────────

class FundDistributionListCreateView(APIView):
    """List all distributions or create a new batch distribution."""

    permission_classes = [IsEnterpriseAdmin]

    def get(self, request):
        enterprise = _get_enterprise(request)
        qs = enterprise.distributions.prefetch_related(
            "items", "items__creator"
        ).order_by("-distributed_at")
        return Response(FundDistributionSerializer(qs, many=True).data)

    def post(self, request):
        enterprise = _get_enterprise(request)
        serializer = CreateFundDistributionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        items_data = data["items"]

        # Resolve creator slugs to profiles
        slugs = [item["creator_slug"] for item in items_data]
        profiles = {
            p.slug: p for p in CreatorProfile.objects.filter(slug__in=slugs)
        }
        missing = [s for s in slugs if s not in profiles]
        if missing:
            return Response(
                {"detail": f"Unknown creator slugs: {missing}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        total = sum(Decimal(str(item["amount"])) for item in items_data)

        dist = FundDistribution.objects.create(
            enterprise=enterprise,
            total_amount=total,
            notes=data.get("notes", ""),
            distributed_by=request.user,
        )

        FundDistributionItem.objects.bulk_create([
            FundDistributionItem(
                distribution=dist,
                creator=profiles[item["creator_slug"]],
                amount=Decimal(str(item["amount"])),
                reference=item.get("reference", ""),
            )
            for item in items_data
        ])

        dist.refresh_from_db()
        return Response(
            FundDistributionSerializer(dist).data,
            status=status.HTTP_201_CREATED,
        )


class FundDistributionDetailView(generics.RetrieveAPIView):
    """Retrieve a single distribution with all items."""

    serializer_class = FundDistributionSerializer
    permission_classes = [IsEnterpriseAdmin]

    def get_queryset(self):
        return FundDistribution.objects.filter(
            enterprise=_get_enterprise(self.request)
        ).prefetch_related("items", "items__creator")


class FundDistributionItemUpdateView(APIView):
    """Update status / reference / paid_at on a single distribution line item."""

    permission_classes = [IsEnterpriseAdmin]

    def patch(self, request, pk):
        enterprise = _get_enterprise(request)
        item = get_object_or_404(
            FundDistributionItem,
            pk=pk,
            distribution__enterprise=enterprise,
        )
        serializer = FundDistributionItemSerializer(item, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
