from django.contrib import admin
from .models import CreatorProfile


@admin.register(CreatorProfile)
class CreatorProfileAdmin(admin.ModelAdmin):
    list_display = ("display_name", "slug", "is_active", "total_tips", "created_at")
    list_filter = ("is_active",)
    prepopulated_fields = {"slug": ("display_name",)}
