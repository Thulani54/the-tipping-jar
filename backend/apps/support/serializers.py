from rest_framework import serializers
from .models import ContactMessage, Dispute


class ContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContactMessage
        fields = ("id", "name", "email", "subject", "message", "created_at")
        read_only_fields = ("id", "created_at")


class DisputeCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dispute
        fields = ("id", "name", "email", "reason", "description", "tip_ref")
        read_only_fields = ("id",)


class DisputeDetailSerializer(serializers.ModelSerializer):
    reason_label = serializers.CharField(source="get_reason_display", read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    reference    = serializers.CharField(read_only=True)

    class Meta:
        model = Dispute
        fields = (
            "id", "reference", "token",
            "name", "email",
            "reason", "reason_label",
            "description", "tip_ref",
            "status", "status_label",
            "admin_notes",
            "created_at", "updated_at",
        )
        read_only_fields = fields
