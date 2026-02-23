import datetime

from django.db.models import Sum
from django.utils.text import slugify
from rest_framework import serializers

from apps.tips.models import Tip

from .models import (
    CommissionRequest,
    CommissionSlot,
    CreatorPost,
    CreatorProfile,
    Jar,
    MilestoneGoal,
    SupportTier,
)


class CreatorPostPublicSerializer(serializers.ModelSerializer):
    """Metadata only — safe for the public tip page."""

    class Meta:
        model  = CreatorPost
        fields = ["id", "title", "post_type", "created_at"]


class CreatorPostSerializer(serializers.ModelSerializer):
    """Full content — returned only to verified tippers."""

    media_url = serializers.SerializerMethodField()

    def get_media_url(self, obj):
        request = self.context.get("request")
        if obj.media_file and request:
            return request.build_absolute_uri(obj.media_file.url)
        return None

    class Meta:
        model  = CreatorPost
        fields = ["id", "title", "body", "post_type", "video_url", "media_url",
                  "is_published", "created_at"]


class CreatorProfileSerializer(serializers.ModelSerializer):
    total_tips = serializers.ReadOnlyField()
    username = serializers.CharField(source="user.username", read_only=True)
    avatar = serializers.ImageField(source="user.avatar", read_only=True)
    has_bank_connected = serializers.SerializerMethodField()
    bank_account_number_masked = serializers.SerializerMethodField()

    class Meta:
        model = CreatorProfile
        fields = (
            "id", "username", "avatar", "display_name", "slug",
            "tagline", "cover_image", "tip_goal", "total_tips",
            "thank_you_message",
            "category", "platforms", "audience_size", "age_group", "audience_gender",
            "is_active", "created_at",
            # Banking
            "bank_name", "bank_account_holder",
            "bank_account_number_masked",
            "bank_routing_number", "bank_account_type", "bank_country",
            "has_bank_connected",
        )
        read_only_fields = (
            "id", "total_tips", "created_at", "stripe_account_id",
            "bank_account_number_masked", "has_bank_connected",
        )

    def get_has_bank_connected(self, obj):
        return bool(obj.bank_name and obj.bank_account_number)

    def get_bank_account_number_masked(self, obj):
        n = obj.bank_account_number
        if not n:
            return ""
        return "••••" + n[-4:] if len(n) >= 4 else "••••"

    def update(self, instance, validated_data):
        # Allow updating bank_account_number (write-only field not in Meta.fields)
        account_number = self.initial_data.get("bank_account_number")
        if account_number is not None:
            instance.bank_account_number = account_number
        return super().update(instance, validated_data)


class JarSerializer(serializers.ModelSerializer):
    total_raised = serializers.ReadOnlyField()
    tip_count = serializers.ReadOnlyField()
    creator_slug = serializers.CharField(source="creator.slug", read_only=True)
    progress_pct = serializers.SerializerMethodField()

    class Meta:
        model = Jar
        fields = (
            "id", "creator_slug", "name", "slug", "description",
            "goal", "total_raised", "tip_count", "progress_pct",
            "is_active", "created_at",
        )
        read_only_fields = (
            "id", "creator_slug", "total_raised", "tip_count",
            "progress_pct", "created_at",
        )
        extra_kwargs = {
            "slug": {"required": False, "allow_blank": True},
        }

    def get_progress_pct(self, obj):
        if not obj.goal or obj.goal == 0:
            return None
        return round(min(float(obj.total_raised) / float(obj.goal) * 100, 100), 1)

    def _unique_slug(self, base_slug, creator, exclude_id=None):
        slug = base_slug
        qs = Jar.objects.filter(creator=creator, slug=slug)
        if exclude_id:
            qs = qs.exclude(id=exclude_id)
        n = 1
        while qs.exists():
            slug = f"{base_slug}-{n}"
            n += 1
            qs = Jar.objects.filter(creator=creator, slug=slug)
            if exclude_id:
                qs = qs.exclude(id=exclude_id)
        return slug

    def create(self, validated_data):
        creator = validated_data["creator"]
        if not validated_data.get("slug"):
            validated_data["slug"] = self._unique_slug(
                slugify(validated_data["name"]), creator
            )
        return super().create(validated_data)

    def update(self, instance, validated_data):
        if "name" in validated_data and not validated_data.get("slug"):
            validated_data["slug"] = self._unique_slug(
                slugify(validated_data["name"]), instance.creator, exclude_id=instance.id
            )
        return super().update(instance, validated_data)


class SupportTierSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportTier
        fields = (
            "id", "name", "price", "description",
            "perks", "is_active", "sort_order", "created_at",
        )
        read_only_fields = ("id", "created_at")


class MilestoneGoalSerializer(serializers.ModelSerializer):
    current_month_total = serializers.SerializerMethodField()
    progress_pct = serializers.SerializerMethodField()

    class Meta:
        model = MilestoneGoal
        fields = (
            "id", "title", "description", "target_amount",
            "current_month_total", "progress_pct",
            "bonus_post", "is_active", "is_achieved", "achieved_at", "created_at",
        )
        read_only_fields = ("id", "current_month_total", "progress_pct", "is_achieved", "achieved_at", "created_at")

    def get_current_month_total(self, obj):
        today = datetime.date.today()
        total = Tip.objects.filter(
            creator=obj.creator,
            status=Tip.Status.COMPLETED,
            created_at__year=today.year,
            created_at__month=today.month,
        ).aggregate(t=Sum("amount"))["t"] or 0
        return float(total)

    def get_progress_pct(self, obj):
        total = self.get_current_month_total(obj)
        if not obj.target_amount:
            return 0
        return round(min(total / float(obj.target_amount) * 100, 100), 1)


class CommissionSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = CommissionSlot
        fields = (
            "id", "is_open", "base_price", "description",
            "turnaround_days", "max_active_requests",
        )
        read_only_fields = ("id",)


class CommissionRequestSerializer(serializers.ModelSerializer):
    creator_display_name = serializers.CharField(source="creator.display_name", read_only=True)
    creator_slug = serializers.CharField(source="creator.slug", read_only=True)

    class Meta:
        model = CommissionRequest
        fields = (
            "id", "creator", "creator_slug", "creator_display_name",
            "fan_name", "fan_email",
            "title", "description", "agreed_price",
            "status", "delivery_note", "created_at",
        )
        read_only_fields = ("id", "creator_display_name", "creator_slug", "created_at")
