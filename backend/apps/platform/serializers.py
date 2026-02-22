from django.utils.text import slugify
from rest_framework import serializers

from .models import Platform, PlatformDocument, PlatformUser


class PlatformDocumentSerializer(serializers.ModelSerializer):
    doc_type_display = serializers.CharField(source="get_doc_type_display", read_only=True)
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = PlatformDocument
        fields = ("id", "doc_type", "doc_type_display", "file_url", "uploaded_at")
        read_only_fields = ("id", "doc_type_display", "file_url", "uploaded_at")

    def get_file_url(self, obj):
        request = self.context.get("request")
        if obj.file and request:
            return request.build_absolute_uri(obj.file.url)
        return None


class PlatformSerializer(serializers.ModelSerializer):
    documents = PlatformDocumentSerializer(many=True, read_only=True)

    class Meta:
        model = Platform
        fields = (
            "id", "name", "slug", "website", "description", "intended_use",
            "company_name_legal", "company_registration_number", "vat_number",
            "contact_name", "contact_email", "contact_phone",
            "approval_status", "rejection_reason",
            "platform_key_prefix", "is_active", "created_at",
            "documents",
        )
        read_only_fields = (
            "id", "slug", "approval_status", "rejection_reason",
            "platform_key_prefix", "created_at",
        )

    def create(self, validated_data):
        if not validated_data.get("slug"):
            validated_data["slug"] = slugify(validated_data["name"])
        return super().create(validated_data)


class PlatformUserSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source="user.email", read_only=True)
    user_id = serializers.IntegerField(source="user.id", read_only=True)

    class Meta:
        model = PlatformUser
        fields = ("id", "user_id", "user_email", "external_id", "created_at")
        read_only_fields = ("id", "user_id", "user_email", "created_at")
