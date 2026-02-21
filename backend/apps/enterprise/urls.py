from django.urls import path
from .views import (
    MyEnterpriseView,
    EnterpriseMemberListView,
    EnterpriseMemberDetailView,
    EnterpriseStatsView,
    FundDistributionListCreateView,
    FundDistributionDetailView,
    FundDistributionItemUpdateView,
)

urlpatterns = [
    # Enterprise profile
    path("me/",                             MyEnterpriseView.as_view(),                 name="enterprise-me"),
    # Creators / members
    path("me/members/",                     EnterpriseMemberListView.as_view(),         name="enterprise-members"),
    path("me/members/<int:pk>/",            EnterpriseMemberDetailView.as_view(),       name="enterprise-member-detail"),
    # Aggregate stats
    path("me/stats/",                       EnterpriseStatsView.as_view(),              name="enterprise-stats"),
    # Fund distributions
    path("me/distributions/",              FundDistributionListCreateView.as_view(),   name="enterprise-distributions"),
    path("me/distributions/<int:pk>/",     FundDistributionDetailView.as_view(),       name="enterprise-distribution-detail"),
    path("me/distribution-items/<int:pk>/",FundDistributionItemUpdateView.as_view(),   name="enterprise-distribution-item"),
]
