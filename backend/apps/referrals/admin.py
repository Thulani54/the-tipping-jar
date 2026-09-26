from django.contrib import admin

from .models import Referral, ReferralCode


@admin.register(ReferralCode)
class ReferralCodeAdmin(admin.ModelAdmin):
    list_display = ("code", "owner", "commission_rate", "is_active", "created_at")
    list_filter = ("is_active",)
    search_fields = ("code", "owner__email", "owner__username")
    list_editable = ("commission_rate", "is_active")
    ordering = ("-created_at",)


@admin.register(Referral)
class ReferralAdmin(admin.ModelAdmin):
    list_display = (
        "referrer",
        "referred_user",
        "commission_rate",
        "status",
        "expires_at",
        "bank_details_submitted_at",
        "signed_up_at",
    )
    list_filter = ("status",)
    search_fields = ("referrer__email", "referred_user__email")
    list_editable = ("status",)
    readonly_fields = ("signed_up_at", "updated_at", "bank_details_submitted_at")
    fieldsets = (
        (None, {"fields": ("referrer", "referred_user", "referral_code", "status")}),
        (
            "Commission",
            {"fields": ("commission_rate", "commission_months", "expires_at")},
        ),
        (
            "Bank Details",
            {
                "fields": (
                    "bank_name",
                    "bank_account_name",
                    "bank_account_number",
                    "bank_details_submitted_at",
                )
            },
        ),
        ("Timestamps", {"fields": ("signed_up_at", "updated_at")}),
    )
