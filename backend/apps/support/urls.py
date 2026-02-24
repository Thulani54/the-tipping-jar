from django.urls import path

from .views import (
    ContactView,
    CreatorDisputeListView,
    DisputeCreateView,
    DisputeDetailView,
    EnterpriseDisputeListView,
)

urlpatterns = [
    path("contact/",                  ContactView.as_view(),              name="contact"),
    path("disputes/",                 DisputeCreateView.as_view(),        name="dispute-create"),
    path("disputes/my/",              CreatorDisputeListView.as_view(),   name="dispute-my"),
    path("disputes/enterprise/",      EnterpriseDisputeListView.as_view(),name="dispute-enterprise"),
    path("disputes/<uuid:token>/",    DisputeDetailView.as_view(),        name="dispute-detail"),
]
