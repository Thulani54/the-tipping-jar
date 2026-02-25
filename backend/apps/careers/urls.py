from django.urls import path

from .views import JobOpeningListView

urlpatterns = [
    path("", JobOpeningListView.as_view(), name="careers-list"),
]
