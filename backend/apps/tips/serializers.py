from rest_framework import serializers
from .models import Tip


class TipSerializer(serializers.ModelSerializer):
    creator_display_name = serializers.CharField(source="creator.display_name", read_only=True)

    class Meta:
        model = Tip
        fields = (
            "id", "creator", "creator_display_name", "tipper_name",
            "amount", "message", "status", "created_at",
        )
        read_only_fields = ("id", "status", "created_at", "creator_display_name")


class CreateTipSerializer(serializers.Serializer):
    creator_slug = serializers.SlugField()
    amount = serializers.DecimalField(max_digits=8, decimal_places=2, min_value=1)
    message = serializers.CharField(max_length=500, required=False, allow_blank=True)
    tipper_name = serializers.CharField(max_length=100, required=False, default="Anonymous")
