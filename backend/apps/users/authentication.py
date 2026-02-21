import hashlib

from django.utils import timezone
from rest_framework import authentication, exceptions


class ApiKeyAuthentication(authentication.BaseAuthentication):
    """
    Authenticates requests using a TippingJar API key.

    Accepted header formats (in priority order):
      1. Authorization: Bearer tj_live_sk_v1_<token>
      2. X-API-Key: tj_live_sk_v1_<token>

    If neither header contains an API key this authenticator returns None,
    allowing other authenticators (e.g. JWT) to run next.
    """

    KEY_PREFIX = "tj_live_sk_v1_"

    def authenticate(self, request):
        raw_key = self._extract_key(request)
        if raw_key is None:
            return None  # not our token — let JWT try

        if not raw_key.startswith(self.KEY_PREFIX):
            return None

        key_hash = hashlib.sha256(raw_key.encode()).hexdigest()

        # Lazy import avoids circular-import issues at module load time
        from .models import ApiKey  # noqa: PLC0415

        try:
            key_obj = ApiKey.objects.select_related("user").get(
                key_hash=key_hash, is_active=True
            )
        except ApiKey.DoesNotExist:
            raise exceptions.AuthenticationFailed("Invalid or revoked API key.")

        # Stamp last_used_at without triggering full model save/signals
        ApiKey.objects.filter(pk=key_obj.pk).update(last_used_at=timezone.now())

        return (key_obj.user, key_obj)

    def _extract_key(self, request):
        auth = request.META.get("HTTP_AUTHORIZATION", "")
        if auth.startswith("Bearer "):
            token = auth[7:].strip()
            if token.startswith(self.KEY_PREFIX):
                return token

        x_key = request.META.get("HTTP_X_API_KEY", "").strip()
        if x_key:
            return x_key

        return None

    def authenticate_header(self, request):
        return 'Bearer realm="TippingJar API"'
