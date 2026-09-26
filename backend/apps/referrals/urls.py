from django.urls import path

from .views import (
    InviteCreatorsView,
    MyReferralsView,
    SubmitBankDetailsView,
    ValidateReferralCodeView,
)

urlpatterns = [
    path("me/", MyReferralsView.as_view(), name="my-referrals"),
    path("validate/<str:code>/", ValidateReferralCodeView.as_view(), name="validate-referral-code"),
    path("invite/", InviteCreatorsView.as_view(), name="invite-creators"),
    path("<int:pk>/bank-details/", SubmitBankDetailsView.as_view(), name="submit-bank-details"),
]
