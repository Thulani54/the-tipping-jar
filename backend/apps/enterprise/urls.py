from django.urls import path

from .views import (
    AdminEnterpriseApproveView,
    AdminEnterpriseRejectView,
    EnterpriseDocumentUploadView,
    EnterpriseMemberDetailView,
    EnterpriseMemberListView,
    EnterpriseStatsView,
    FundDistributionDetailView,
    FundDistributionItemUpdateView,
    FundDistributionListCreateView,
    MyEnterpriseView,
)

urlpatterns = [
    # Enterprise profile
    path("me/",                              MyEnterpriseView.as_view(),                 name="enterprise-me"),
    # Document upload (pending enterprises can upload too)
    path("me/documents/",                    EnterpriseDocumentUploadView.as_view(),     name="enterprise-documents"),
    # Creators / members
    path("me/members/",                      EnterpriseMemberListView.as_view(),         name="enterprise-members"),
    path("me/members/<int:pk>/",             EnterpriseMemberDetailView.as_view(),       name="enterprise-member-detail"),
    # Aggregate stats
    path("me/stats/",                        EnterpriseStatsView.as_view(),              name="enterprise-stats"),
    # Fund distributions
    path("me/distributions/",               FundDistributionListCreateView.as_view(),   name="enterprise-distributions"),
    path("me/distributions/<int:pk>/",      FundDistributionDetailView.as_view(),       name="enterprise-distribution-detail"),
    path("me/distribution-items/<int:pk>/", FundDistributionItemUpdateView.as_view(),   name="enterprise-distribution-item"),
    # Admin approval
    path("admin/<int:pk>/approve/",          AdminEnterpriseApproveView.as_view(),       name="enterprise-admin-approve"),
    path("admin/<int:pk>/reject/",           AdminEnterpriseRejectView.as_view(),        name="enterprise-admin-reject"),
]
