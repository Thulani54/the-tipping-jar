from django.urls import path

from .views import ContactView, DisputeCreateView, DisputeDetailView

urlpatterns = [
    path("contact/",              ContactView.as_view(),       name="contact"),
    path("disputes/",             DisputeCreateView.as_view(), name="dispute-create"),
    path("disputes/<uuid:token>/", DisputeDetailView.as_view(), name="dispute-detail"),
]
