from django.contrib import admin
from core.admin_site import admin_site
from .emails import send_dispute_status_update
from .models import ContactMessage, Dispute


@admin.register(ContactMessage, site=admin_site)
class ContactMessageAdmin(admin.ModelAdmin):
    list_display  = ("name", "email", "subject", "is_resolved", "created_at")
    list_filter   = ("is_resolved", "subject")
    search_fields = ("name", "email", "message")
    readonly_fields = ("created_at",)
    date_hierarchy = "created_at"
    actions = ["mark_resolved"]

    @admin.action(description="Mark selected messages as resolved")
    def mark_resolved(self, request, queryset):
        updated = queryset.update(is_resolved=True)
        self.message_user(request, f"{updated} message(s) marked as resolved.")


@admin.register(Dispute, site=admin_site)
class DisputeAdmin(admin.ModelAdmin):
    list_display   = ("reference", "name", "email", "reason", "status", "created_at")
    list_filter    = ("status", "reason")
    search_fields  = ("name", "email", "description", "tip_ref")
    readonly_fields = ("token", "reference", "tracking_url", "created_at", "updated_at")
    date_hierarchy  = "created_at"
    actions = ["send_status_update_email", "mark_investigating", "mark_resolved", "mark_closed"]

    @admin.action(description="Send status-update email to selected disputes")
    def send_status_update_email(self, request, queryset):
        count = 0
        for dispute in queryset:
            send_dispute_status_update(dispute)
            count += 1
        self.message_user(request, f"Sent {count} status update email(s).")

    @admin.action(description="Mark as Under Investigation")
    def mark_investigating(self, request, queryset):
        queryset.update(status=Dispute.Status.INVESTIGATING)

    @admin.action(description="Mark as Resolved")
    def mark_resolved(self, request, queryset):
        queryset.update(status=Dispute.Status.RESOLVED)

    @admin.action(description="Mark as Closed")
    def mark_closed(self, request, queryset):
        queryset.update(status=Dispute.Status.CLOSED)
