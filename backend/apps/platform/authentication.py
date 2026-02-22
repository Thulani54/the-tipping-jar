import hashlib

from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed


class PlatformKeyAuthentication(BaseAuthentication):
    """
    Reads the X-Platform-Key header, SHA-256 hashes it,
    and looks up the matching Platform record.
    Returns (platform.owner, platform) on success so request.user
    is set to the platform owner and request.auth is the Platform.
    """

    def authenticate(self, request):
        raw_key = request.headers.get("X-Platform-Key", "").strip()
        if not raw_key or not raw_key.startswith("tj_platform_sk_v1_"):
            return None  # Not a platform key request — pass to next authenticator

        from .models import Platform  # local import to avoid circular

        key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
        try:
            platform = Platform.objects.select_related("owner").get(platform_key_hash=key_hash)
        except Platform.DoesNotExist:
            raise AuthenticationFailed("Invalid platform key.")

        if not platform.is_active:
            raise AuthenticationFailed("Platform is inactive.")
        if platform.approval_status != Platform.ApprovalStatus.APPROVED:
            raise AuthenticationFailed("Platform is not approved.")

        return (platform.owner, platform)

    def authenticate_header(self, request):
        return "X-Platform-Key"
