from django.urls import path

from .views import (
    AdminPlatformApproveView,
    AdminPlatformRejectView,
    MyPlatformView,
    PlatformApplyView,
    PlatformCreatorListView,
    PlatformDocumentUploadView,
    PlatformTipView,
    PlatformUserListCreateView,
)

urlpatterns = [
    # Application flow (no key required — JWT or anonymous)
    path("apply/",                        PlatformApplyView.as_view(),            name="platform-apply"),
    path("apply/<int:pk>/documents/",     PlatformDocumentUploadView.as_view(),   name="platform-apply-docs"),
    # Platform key authenticated
    path("me/",                           MyPlatformView.as_view(),               name="platform-me"),
    path("users/",                        PlatformUserListCreateView.as_view(),   name="platform-users"),
    path("creators/",                     PlatformCreatorListView.as_view(),      name="platform-creators"),
    path("tips/",                         PlatformTipView.as_view(),              name="platform-tips"),
    # Admin
    path("admin/<int:pk>/approve/",       AdminPlatformApproveView.as_view(),     name="platform-admin-approve"),
    path("admin/<int:pk>/reject/",        AdminPlatformRejectView.as_view(),      name="platform-admin-reject"),
]
