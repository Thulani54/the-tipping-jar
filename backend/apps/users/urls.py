from django.urls import path

from .views import (
    ApiKeyListCreateView,
    ApiKeyRevokeView,
    DeleteAccountView,
    MeView,
    OtpRequestView,
    OtpSwitchMethodView,
    OtpVerifyView,
    RegisterView,
    RegistrationVerifyConfirmView,
    RegistrationVerifyRequestView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("me/", MeView.as_view(), name="me"),
    # Registration email verification (one-time, does not require 2FA to be enabled)
    path("verify-registration/", RegistrationVerifyRequestView.as_view(), name="verify-registration-request"),
    path("verify-registration/confirm/", RegistrationVerifyConfirmView.as_view(), name="verify-registration-confirm"),
    # 2FA OTP
    path("otp/request/", OtpRequestView.as_view(), name="otp-request"),
    path("otp/verify/", OtpVerifyView.as_view(), name="otp-verify"),
    path("otp/switch-method/", OtpSwitchMethodView.as_view(), name="otp-switch-method"),
    # Account management
    path("me/delete/", DeleteAccountView.as_view(), name="delete-account"),
    # API key management
    path("api-keys/", ApiKeyListCreateView.as_view(), name="api-key-list-create"),
    path("api-keys/<int:pk>/", ApiKeyRevokeView.as_view(), name="api-key-revoke"),
]
