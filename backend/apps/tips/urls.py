from django.urls import path
from .views import CreatorTipsView, InitiateTipView

urlpatterns = [
    path("initiate/", InitiateTipView.as_view(), name="initiate-tip"),
    path("<slug:slug>/", CreatorTipsView.as_view(), name="creator-tips"),
]
