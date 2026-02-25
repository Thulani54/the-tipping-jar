from rest_framework import generics
from rest_framework.permissions import AllowAny

from .models import JobOpening
from .serializers import JobOpeningSerializer


class JobOpeningListView(generics.ListAPIView):
    """Public list of active job openings."""

    permission_classes = [AllowAny]
    serializer_class = JobOpeningSerializer

    def get_queryset(self):
        return JobOpening.objects.filter(is_active=True)
