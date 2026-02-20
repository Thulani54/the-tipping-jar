from django.urls import path
from .views import CreatorListView, CreatorDetailView, MyCreatorProfileView

urlpatterns = [
    path("", CreatorListView.as_view(), name="creator-list"),
    path("me/", MyCreatorProfileView.as_view(), name="my-creator-profile"),
    path("<slug:slug>/", CreatorDetailView.as_view(), name="creator-detail"),
]
