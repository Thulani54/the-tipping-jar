from rest_framework import serializers
from .models import CreatorProfile


class CreatorProfileSerializer(serializers.ModelSerializer):
    total_tips = serializers.ReadOnlyField()
    username = serializers.CharField(source="user.username", read_only=True)
    avatar = serializers.ImageField(source="user.avatar", read_only=True)

    class Meta:
        model = CreatorProfile
        fields = (
            "id", "username", "avatar", "display_name", "slug",
            "tagline", "cover_image", "tip_goal", "total_tips",
            "is_active", "created_at",
        )
        read_only_fields = ("id", "total_tips", "created_at", "stripe_account_id")
