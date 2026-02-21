from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from core.admin_site import admin_site

from .models import OTP, ApiKey, User


@admin.register(User, site=admin_site)
class CustomUserAdmin(UserAdmin):
    list_display = ("email", "username", "role", "otp_method", "phone_number", "is_active", "date_joined")
    list_filter = ("role", "otp_method", "is_staff", "is_active")
    search_fields = ("email", "username", "phone_number")
    ordering = ("-date_joined",)
    fieldsets = UserAdmin.fieldsets + (
        ("Profile", {"fields": ("role", "avatar", "bio")}),
        ("Contact & OTP", {"fields": ("phone_number", "otp_method")}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ("Profile", {"fields": ("email", "role")}),
    )
    actions = ["send_sms_notification"]

    @admin.action(description="📱 Send SMS notification to selected users")
    def send_sms_notification(self, request, queryset):
        from apps.support.sms import send_sms
        message = "Hello from TippingJar! This is a notification from our team. Visit tippingjar.co.za for more info."
        sent, skipped = 0, 0
        for user in queryset:
            if user.phone_number:
                result = send_sms(user.phone_number, message)
                if result["success"]:
                    sent += 1
                else:
                    skipped += 1
            else:
                skipped += 1
        self.message_user(
            request,
            f"SMS sent: {sent} | Skipped (no phone / error): {skipped}",
        )


@admin.register(OTP, site=admin_site)
class OTPAdmin(admin.ModelAdmin):
    list_display = ("user", "method", "is_used", "created_at", "expires_at")
    list_filter = ("method", "is_used")
    search_fields = ("user__email",)
    readonly_fields = ("code", "created_at", "expires_at", "method", "user")
    ordering = ("-created_at",)
    date_hierarchy = "created_at"


@admin.register(ApiKey, site=admin_site)
class ApiKeyAdmin(admin.ModelAdmin):
    list_display = ("user", "name", "prefix", "is_active", "created_at", "last_used_at")
    list_filter = ("is_active",)
    search_fields = ("user__email", "name", "prefix")
    readonly_fields = ("key_hash", "prefix", "created_at", "last_used_at")
    actions = ["revoke_keys"]

    @admin.action(description="Revoke selected API keys")
    def revoke_keys(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f"{updated} API key(s) revoked.")
