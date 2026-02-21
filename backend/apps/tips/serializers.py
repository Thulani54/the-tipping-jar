from rest_framework import serializers
from .models import Tip


class TipSerializer(serializers.ModelSerializer):
    creator_display_name = serializers.CharField(source="creator.display_name", read_only=True)
    creator_slug = serializers.CharField(source="creator.slug", read_only=True)
    jar_name = serializers.SerializerMethodField()

    class Meta:
        model = Tip
        fields = (
            "id", "creator", "creator_slug", "creator_display_name",
            "jar", "jar_name",
            "tipper_name", "amount", "message", "status",
            "platform_fee", "service_fee", "creator_net",
            "paystack_reference", "created_at",
        )
        read_only_fields = (
            "id", "status", "created_at",
            "creator_display_name", "creator_slug", "jar_name",
            "platform_fee", "service_fee", "creator_net", "paystack_reference",
        )

    def get_jar_name(self, obj):
        return obj.jar.name if obj.jar else None


class CreateTipSerializer(serializers.Serializer):
    creator_slug = serializers.SlugField()
    amount = serializers.DecimalField(max_digits=8, decimal_places=2, min_value=1)
    message = serializers.CharField(max_length=500, required=False, allow_blank=True)
    tipper_name = serializers.CharField(max_length=100, required=False, default="Anonymous")
    tipper_email = serializers.EmailField(required=False, allow_blank=True, default="")
    jar_id = serializers.IntegerField(required=False, allow_null=True)
