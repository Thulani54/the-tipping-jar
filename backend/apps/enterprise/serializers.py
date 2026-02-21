from django.utils.text import slugify
from rest_framework import serializers

from .models import Enterprise, EnterpriseMembership, FundDistribution, FundDistributionItem


class EnterpriseMembershipSerializer(serializers.ModelSerializer):
    creator_id = serializers.IntegerField(source="creator.id", read_only=True)
    creator_slug = serializers.CharField(source="creator.slug", read_only=True)
    display_name = serializers.CharField(source="creator.display_name", read_only=True)
    avatar = serializers.ImageField(source="creator.user.avatar", read_only=True)
    tagline = serializers.CharField(source="creator.tagline", read_only=True)
    total_tips = serializers.ReadOnlyField(source="creator.total_tips")

    class Meta:
        model = EnterpriseMembership
        fields = (
            "id", "creator_id", "creator_slug", "display_name",
            "avatar", "tagline", "total_tips", "joined_at", "is_active",
        )
        read_only_fields = ("id", "joined_at")


class EnterpriseSerializer(serializers.ModelSerializer):
    creator_count = serializers.ReadOnlyField()
    logo = serializers.ImageField(required=False)

    class Meta:
        model = Enterprise
        fields = (
            "id", "name", "slug", "logo", "website",
            "plan", "is_active", "creator_count", "created_at",
        )
        read_only_fields = ("id", "slug", "creator_count", "created_at")

    def create(self, validated_data):
        if not validated_data.get("slug"):
            validated_data["slug"] = slugify(validated_data["name"])
        return super().create(validated_data)


class FundDistributionItemSerializer(serializers.ModelSerializer):
    creator_slug = serializers.CharField(source="creator.slug", read_only=True)
    display_name = serializers.CharField(source="creator.display_name", read_only=True)
    distribution_reference = serializers.CharField(source="distribution.reference", read_only=True)

    class Meta:
        model = FundDistributionItem
        fields = (
            "id", "distribution_reference", "creator_slug", "display_name",
            "amount", "status", "reference", "paid_at",
        )
        read_only_fields = ("id", "distribution_reference", "creator_slug", "display_name")


class FundDistributionSerializer(serializers.ModelSerializer):
    items = FundDistributionItemSerializer(many=True, read_only=True)
    reference = serializers.ReadOnlyField()
    distributed_by_username = serializers.CharField(
        source="distributed_by.username", read_only=True
    )

    class Meta:
        model = FundDistribution
        fields = (
            "id", "reference", "total_amount", "notes",
            "distributed_by_username", "distributed_at", "items",
        )
        read_only_fields = ("id", "reference", "distributed_by_username", "distributed_at")


class CreateFundDistributionSerializer(serializers.Serializer):
    """Validates a batch fund distribution creation request."""

    notes = serializers.CharField(required=False, allow_blank=True, default="")
    items = serializers.ListField(
        child=serializers.DictField(),
        min_length=1,
    )

    def validate_items(self, items):
        for item in items:
            if "creator_slug" not in item:
                raise serializers.ValidationError("Each item must have a 'creator_slug'.")
            try:
                amount = float(item.get("amount", 0))
            except (TypeError, ValueError):
                raise serializers.ValidationError("Each item must have a valid numeric 'amount'.")
            if amount <= 0:
                raise serializers.ValidationError("Amount must be greater than 0.")
        return items
