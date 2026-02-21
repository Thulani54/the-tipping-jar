from rest_framework import serializers

from .models import OTP, ApiKey, User


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ("id", "username", "email", "password", "role")

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "username", "email", "role", "avatar", "bio", "phone_number", "otp_method")
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
