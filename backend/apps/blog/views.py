from rest_framework import generics
from rest_framework.permissions import AllowAny

from .models import BlogPost
from .serializers import BlogPostDetailSerializer, BlogPostListSerializer


class BlogPostListView(generics.ListAPIView):
    """Public list of published blog posts, newest first."""

    permission_classes = [AllowAny]
    serializer_class = BlogPostListSerializer

    def get_queryset(self):
        return BlogPost.objects.filter(is_published=True)


class BlogPostDetailView(generics.RetrieveAPIView):
    """Public detail for a single published blog post (by slug)."""

    permission_classes = [AllowAny]
    serializer_class = BlogPostDetailSerializer
    lookup_field = "slug"

    def get_queryset(self):
        return BlogPost.objects.filter(is_published=True)
