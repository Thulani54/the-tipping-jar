from rest_framework import serializers

from .models import BlogPost


class BlogPostListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for the blog listing page."""

    class Meta:
        model = BlogPost
        fields = [
            "id",
            "title",
            "slug",
            "category",
            "excerpt",
            "cover_image",
            "author_name",
            "read_time",
            "created_at",
        ]


class BlogPostDetailSerializer(serializers.ModelSerializer):
    """Full serializer including the HTML content body."""

    class Meta:
        model = BlogPost
        fields = [
            "id",
            "title",
            "slug",
            "category",
            "excerpt",
            "content",
            "cover_image",
            "author_name",
            "read_time",
            "created_at",
            "updated_at",
        ]
