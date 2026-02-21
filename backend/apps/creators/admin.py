from django.contrib import admin

from core.admin_site import admin_site

from .models import CreatorProfile, Jar


@admin.register(CreatorProfile, site=admin_site)
class CreatorProfileAdmin(admin.ModelAdmin):
    list_display = ("display_name", "slug", "is_active", "total_tips", "created_at")
    list_filter = ("is_active", "bank_country")
    search_fields = ("display_name", "slug", "user__email")
    prepopulated_fields = {"slug": ("display_name",)}
    readonly_fields = ("created_at", "total_tips")

    def get_queryset(self, request):
        return super().get_queryset(request).select_related("user")


@admin.register(Jar, site=admin_site)
class JarAdmin(admin.ModelAdmin):
    list_display = ("name", "creator", "is_active", "total_raised", "tip_count", "created_at")
    list_filter = ("is_active",)
    search_fields = ("name", "creator__display_name")
    readonly_fields = ("total_raised", "tip_count", "created_at")
