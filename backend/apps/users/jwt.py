from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView


class TippingJarTokenSerializer(TokenObtainPairSerializer):
    """Extends the default JWT response to include basic user info."""

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = {
            "id": self.user.id,
            "email": self.user.email,
            "username": self.user.username,
            "role": self.user.role,
            "two_fa_enabled": self.user.two_fa_enabled,
        }
        return data


class TippingJarTokenView(TokenObtainPairView):
    serializer_class = TippingJarTokenSerializer
