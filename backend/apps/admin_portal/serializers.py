from rest_framework import serializers

from apps.blog.models import BlogPost
from apps.careers.models import JobOpening
from apps.creators.models import CreatorKycDocument, CreatorProfile
from apps.enterprise.models import Enterprise, EnterpriseDocument
from apps.tips.models import Tip
from apps.users.models import User


class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "email", "username", "first_name", "last_name",
            "role", "phone_number", "two_fa_enabled", "is_active",
            "date_joined", "last_login",
        ]
        read_only_fields = ["id", "email", "username", "date_joined", "last_login"]


class AdminTipSerializer(serializers.ModelSerializer):
    creator_name = serializers.CharField(source="creator.display_name", read_only=True)
    creator_slug = serializers.CharField(source="creator.slug", read_only=True)

    class Meta:
        model = Tip
        fields = [
            "id", "creator_name", "creator_slug",
            "tipper_name", "tipper_email", "amount",
            "platform_fee", "service_fee", "creator_net",
            "status", "paystack_reference", "message",
            "created_at",
        ]


class AdminKycDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = CreatorKycDocument
        fields = [
            "id", "doc_type", "file", "status",
            "decline_reason", "uploaded_at", "reviewed_at",
        ]


class AdminCreatorSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source="user.email", read_only=True)
    kyc_documents = AdminKycDocumentSerializer(many=True, read_only=True)
    total_tips = serializers.SerializerMethodField()

    class Meta:
        model = CreatorProfile
        fields = [
            "id", "display_name", "slug", "email",
            "kyc_status", "kyc_decline_reason",
            "bank_name", "bank_account_holder", "bank_account_number",
            "bank_routing_number", "bank_account_type", "bank_country",
            "paystack_subaccount_code", "is_active",
            "category", "created_at", "total_tips",
            "kyc_documents",
        ]

    def get_total_tips(self, obj):
        return float(obj.total_tips)


class AdminEnterpriseDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = EnterpriseDocument
        fields = ["id", "doc_type", "file", "uploaded_at"]


class AdminEnterpriseSerializer(serializers.ModelSerializer):
    owner_email = serializers.EmailField(source="user.email", read_only=True)
    documents = AdminEnterpriseDocumentSerializer(many=True, read_only=True)

    class Meta:
        model = Enterprise
        fields = [
            "id", "company_name", "registration_number", "vat_number",
            "contact_email", "contact_phone", "plan",
            "approval_status", "rejection_reason",
            "owner_email", "created_at", "documents",
        ]


class AdminBlogSerializer(serializers.ModelSerializer):
    class Meta:
        model = BlogPost
        fields = [
            "id", "title", "slug", "category", "excerpt", "content",
            "cover_image", "author_name", "read_time", "is_published",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class AdminJobSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobOpening
        fields = [
            "id", "title", "department", "location",
            "employment_type", "description", "is_active",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]
