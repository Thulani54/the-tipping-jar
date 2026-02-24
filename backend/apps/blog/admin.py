from django.contrib import admin
from django_summernote.admin import SummernoteModelAdmin

from core.admin_site import admin_site

from .models import BlogPost


@admin.register(BlogPost, site=admin_site)
class BlogPostAdmin(SummernoteModelAdmin):
    summernote_fields = ("content",)

    list_display = ("title", "category", "author_name", "is_published", "created_at")
    list_filter = ("is_published", "category")
    search_fields = ("title", "excerpt", "author_name")
    prepopulated_fields = {"slug": ("title",)}
    readonly_fields = ("created_at", "updated_at")
    list_editable = ("is_published",)

    fieldsets = (
        (
            "Post Details",
            {
                "fields": (
                    "title",
                    "slug",
                    "category",
                    "author_name",
                    "read_time",
                    "cover_image",
                    "is_published",
                )
            },
        ),
        (
            "Content",
            {
                "fields": ("excerpt", "content"),
                "description": (
                    "Use the toolbar above to apply bold, italic, underline, "
                    "headings, lists, links, and more."
                ),
            },
        ),
        (
            "Timestamps",
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )
