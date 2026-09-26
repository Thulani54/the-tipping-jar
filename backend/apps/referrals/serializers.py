from rest_framework import serializers

from .models import Referral, ReferralCode


class ReferralCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReferralCode
        fields = ("code", "commission_rate", "is_active", "created_at")
        read_only_fields = fields


class ReferralSerializer(serializers.ModelSerializer):
    referred_user_email = serializers.EmailField(
        source="referred_user.email", read_only=True
    )
    referred_user_name = serializers.SerializerMethodField()
    days_remaining = serializers.SerializerMethodField()

    def get_referred_user_name(self, obj):
        u = obj.referred_user
        return u.get_full_name() or u.username

    def get_days_remaining(self, obj):
        return obj.days_remaining

    class Meta:
        model = Referral
        fields = (
            "id",
            "referred_user_email",
            "referred_user_name",
            "commission_rate",
            "commission_months",
            "expires_at",
            "status",
            "days_remaining",
            "signed_up_at",
            "bank_details_submitted_at",
        )
        read_only_fields = fields


class BankDetailsSerializer(serializers.Serializer):
    bank_name = serializers.CharField(max_length=100)
    bank_account_name = serializers.CharField(max_length=150)
    bank_account_number = serializers.CharField(max_length=30)
