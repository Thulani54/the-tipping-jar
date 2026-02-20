from django.contrib import admin
from .models import Tip


@admin.register(Tip)
class TipAdmin(admin.ModelAdmin):
    list_display = ("tipper_name", "creator", "amount", "status", "created_at")
    list_filter = ("status",)
    search_fields = ("tipper_name", "creator__display_name", "stripe_payment_intent_id")
