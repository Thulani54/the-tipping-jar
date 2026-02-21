from django.contrib import admin

from core.admin_site import admin_site

from .models import Tip


@admin.register(Tip, site=admin_site)
class TipAdmin(admin.ModelAdmin):
    list_display = ("tipper_name", "creator", "amount", "status", "created_at")
    list_filter = ("status", "created_at")
    search_fields = ("tipper_name", "creator__display_name", "stripe_payment_intent_id", "message")
    readonly_fields = ("stripe_payment_intent_id", "created_at")
    date_hierarchy = "created_at"
    ordering = ("-created_at",)

    def get_queryset(self, request):
        return super().get_queryset(request).select_related("creator", "tipper", "jar")
