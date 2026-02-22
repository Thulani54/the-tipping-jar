from django.contrib import admin

from core.admin_site import admin_site

from .models import Platform, PlatformDocument, PlatformUser


class PlatformDocumentInline(admin.TabularInline):
    model = PlatformDocument
    extra = 0
    readonly_fields = ("uploaded_at",)
    fields = ("doc_type", "file", "uploaded_at")


class PlatformUserInline(admin.TabularInline):
    model = PlatformUser
    extra = 0
    readonly_fields = ("created_at",)
    fields = ("user", "external_id", "created_at")
    raw_id_fields = ("user",)


@admin.register(Platform, site=admin_site)
class PlatformAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "approval_status", "platform_key_prefix", "is_active", "created_at")
    list_filter = ("approval_status", "is_active")
    search_fields = ("name", "slug", "owner__email", "company_name_legal")
    readonly_fields = ("created_at", "updated_at", "platform_key_prefix", "platform_key_hash")
    inlines = [PlatformDocumentInline, PlatformUserInline]

    fieldsets = (
        (None, {"fields": ("owner", "name", "slug", "website", "description", "intended_use", "is_active")}),
        ("Approval", {"fields": ("approval_status", "rejection_reason")}),
        ("Company Info", {"fields": (
            "company_name_legal", "company_registration_number", "vat_number",
            "contact_name", "contact_email", "contact_phone",
        )}),
        ("API Key", {"fields": ("platform_key_prefix", "platform_key_hash")}),
        ("Timestamps", {"fields": ("created_at", "updated_at")}),
    )

    actions = ["approve_platforms", "reject_platforms", "suspend_platforms"]

    @admin.action(description="Approve selected platforms (generates new API key via admin API)")
    def approve_platforms(self, request, queryset):
        approved = 0
        for platform in queryset:
            raw_key, key_hash, key_prefix = Platform.generate_key()
            platform.platform_key_hash = key_hash
            platform.platform_key_prefix = key_prefix
            platform.approval_status = Platform.ApprovalStatus.APPROVED
            platform.rejection_reason = ""
            platform.save(update_fields=["platform_key_hash", "platform_key_prefix", "approval_status", "rejection_reason"])
            approved += 1
        self.message_user(request, f"{approved} platform(s) approved. Keys generated — use the API endpoint to retrieve raw keys.")

    @admin.action(description="Reject selected platforms")
    def reject_platforms(self, request, queryset):
        updated = queryset.update(approval_status=Platform.ApprovalStatus.REJECTED)
        self.message_user(request, f"{updated} platform(s) rejected.")

    @admin.action(description="Suspend selected platforms")
    def suspend_platforms(self, request, queryset):
        updated = queryset.update(approval_status=Platform.ApprovalStatus.SUSPENDED)
        self.message_user(request, f"{updated} platform(s) suspended.")


@admin.register(PlatformDocument, site=admin_site)
class PlatformDocumentAdmin(admin.ModelAdmin):
    list_display = ("platform", "doc_type", "uploaded_at")
    list_filter = ("doc_type",)
    search_fields = ("platform__name",)
    readonly_fields = ("uploaded_at",)
    raw_id_fields = ("platform",)


@admin.register(PlatformUser, site=admin_site)
class PlatformUserAdmin(admin.ModelAdmin):
    list_display = ("platform", "user", "external_id", "created_at")
    list_filter = ("platform",)
    search_fields = ("platform__name", "user__email", "external_id")
    readonly_fields = ("created_at",)
    raw_id_fields = ("platform", "user")
