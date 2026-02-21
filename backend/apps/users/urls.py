from django.urls import path

from .views import (
    ApiKeyListCreateView,
    ApiKeyRevokeView,
    MeView,
    OtpRequestView,
    OtpSwitchMethodView,
    OtpVerifyView,
    RegisterView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("me/", MeView.as_view(), name="me"),
    # OTP
    path("otp/request/", OtpRequestView.as_view(), name="otp-request"),
    path("otp/verify/", OtpVerifyView.as_view(), name="otp-verify"),
    path("otp/switch-method/", OtpSwitchMethodView.as_view(), name="otp-switch-method"),
    # API key management
    path("api-keys/", ApiKeyListCreateView.as_view(), name="api-key-list-create"),
    path("api-keys/<int:pk>/", ApiKeyRevokeView.as_view(), name="api-key-revoke"),
]
