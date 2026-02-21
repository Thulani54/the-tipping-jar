from django.urls import path
from .views import (
    CreatorListView,
    CreatorDetailView,
    MyCreatorProfileView,
    MyDashboardStatsView,
    MyJarListCreateView,
    MyJarDetailView,
    PublicCreatorJarsView,
    PublicJarDetailView,
)

urlpatterns = [
    path("", CreatorListView.as_view(), name="creator-list"),
    path("me/", MyCreatorProfileView.as_view(), name="my-creator-profile"),
    path("me/stats/", MyDashboardStatsView.as_view(), name="my-dashboard-stats"),
    path("me/jars/", MyJarListCreateView.as_view(), name="my-jar-list"),
    path("me/jars/<int:pk>/", MyJarDetailView.as_view(), name="my-jar-detail"),
    path("<slug:slug>/jars/", PublicCreatorJarsView.as_view(), name="creator-jars"),
    path("<slug:slug>/jars/<slug:jar_slug>/", PublicJarDetailView.as_view(), name="creator-jar-detail"),
    path("<slug:slug>/", CreatorDetailView.as_view(), name="creator-detail"),
]
