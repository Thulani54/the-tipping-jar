from rest_framework import serializers

from .models import OTP, ApiKey, User


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    first_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    # Referral
    referral_code = serializers.CharField(max_length=20, required=False, allow_blank=True, write_only=True)
    # Minor / guardian
    is_minor = serializers.BooleanField(required=False, default=False)
    guardian_name = serializers.CharField(max_length=200, required=False, allow_blank=True)
    guardian_email = serializers.EmailField(required=False, allow_blank=True)
    guardian_phone = serializers.CharField(max_length=20, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = (
            "id", "username", "email", "password", "role",
            "phone_number", "first_name", "last_name",
            "referral_code", "is_minor", "guardian_name", "guardian_email", "guardian_phone",
        )

    def create(self, validated_data):
        # Pop non-model fields before creating
        validated_data.pop("referral_code", None)
        return User.objects.create_user(**validated_data)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id", "username", "email", "role", "avatar", "bio",
            "phone_number", "otp_method", "two_fa_enabled",
            "gender", "date_of_birth", "first_name", "last_name",
        )
        read_only_fields = ("id", "email")


class OtpRequestSerializer(serializers.Serializer):
    method = serializers.ChoiceField(
        choices=OTP.Method.choices,
        required=False,
        help_text="Delivery channel: 'email' or 'sms'. Defaults to the user's saved preference.",
    )


class ApiKeySerializer(serializers.ModelSerializer):
    """Read serializer — never exposes key_hash."""

    class Meta:
        model = ApiKey
        fields = ("id", "name", "prefix", "is_active", "created_at", "last_used_at")
        read_only_fields = fields
