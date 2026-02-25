from django.urls import path

from .views import (
    AdminBlogDetailView,
    AdminBlogListCreateView,
    AdminCreatorListView,
    AdminEnterpriseApproveView,
    AdminEnterpriseListView,
    AdminEnterpriseRejectView,
    AdminJobDetailView,
    AdminJobListCreateView,
    AdminKycApproveView,
    AdminKycDeclineView,
    AdminStatsView,
    AdminTipListView,
    AdminUserDetailView,
    AdminUserListView,
)

urlpatterns = [
    path("stats/",                          AdminStatsView.as_view(),             name="admin-stats"),
    path("users/",                          AdminUserListView.as_view(),          name="admin-users"),
    path("users/<int:pk>/",                 AdminUserDetailView.as_view(),        name="admin-user-detail"),
    path("tips/",                           AdminTipListView.as_view(),           name="admin-tips"),
    path("creators/",                       AdminCreatorListView.as_view(),       name="admin-creators"),
    path("creators/<int:pk>/kyc/approve/",  AdminKycApproveView.as_view(),        name="admin-kyc-approve"),
    path("creators/<int:pk>/kyc/decline/",  AdminKycDeclineView.as_view(),        name="admin-kyc-decline"),
    path("enterprises/",                    AdminEnterpriseListView.as_view(),    name="admin-enterprises"),
    path("enterprises/<int:pk>/approve/",   AdminEnterpriseApproveView.as_view(), name="admin-enterprise-approve"),
    path("enterprises/<int:pk>/reject/",    AdminEnterpriseRejectView.as_view(),  name="admin-enterprise-reject"),
    path("blog/",                           AdminBlogListCreateView.as_view(),    name="admin-blog-list"),
    path("blog/<slug:slug>/",               AdminBlogDetailView.as_view(),        name="admin-blog-detail"),
    path("careers/",                        AdminJobListCreateView.as_view(),     name="admin-jobs-list"),
    path("careers/<int:pk>/",               AdminJobDetailView.as_view(),         name="admin-job-detail"),
]
