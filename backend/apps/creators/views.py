from rest_framework import generics, permissions
from .models import CreatorProfile
from .serializers import CreatorProfileSerializer


class CreatorListView(generics.ListAPIView):
    queryset = CreatorProfile.objects.filter(is_active=True).order_by("-created_at")
    serializer_class = CreatorProfileSerializer
    permission_classes = [permissions.AllowAny]


class CreatorDetailView(generics.RetrieveAPIView):
    queryset = CreatorProfile.objects.filter(is_active=True)
    serializer_class = CreatorProfileSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = "slug"


class MyCreatorProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = CreatorProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        profile, _ = CreatorProfile.objects.get_or_create(
            user=self.request.user,
            defaults={"slug": self.request.user.username, "display_name": self.request.user.username},
        )
        return profile
