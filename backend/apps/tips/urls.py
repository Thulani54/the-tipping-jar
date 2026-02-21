from django.urls import path

from .views import CreatorTipsView, FanTipsView, InitiateTipView, MyTipsView, VerifyTipView

urlpatterns = [
    path("initiate/",          InitiateTipView.as_view(),  name="initiate-tip"),
    path("verify/<str:reference>/", VerifyTipView.as_view(), name="verify-tip"),
    path("me/",                MyTipsView.as_view(),        name="my-tips"),
    path("sent/",              FanTipsView.as_view(),       name="fan-tips-sent"),
    path("<slug:slug>/",       CreatorTipsView.as_view(),   name="creator-tips"),
]
