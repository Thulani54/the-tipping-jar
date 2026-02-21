from django.contrib import admin
from core.admin_site import admin_site
from .models import Enterprise, EnterpriseMembership, FundDistribution, FundDistributionItem


class EnterpriseMembershipInline(admin.TabularInline):
    model = EnterpriseMembership
    extra = 0
    readonly_fields = ("joined_at",)
    fields = ("creator", "is_active", "joined_at")
    raw_id_fields = ("creator",)


class FundDistributionItemInline(admin.TabularInline):
    model = FundDistributionItem
    extra = 0
    readonly_fields = ("distribution",)
    fields = ("creator", "amount", "status", "reference", "paid_at")
    raw_id_fields = ("creator",)


@admin.register(Enterprise, site=admin_site)
class EnterpriseAdmin(admin.ModelAdmin):
    list_display = ("name", "plan", "admin", "creator_count", "is_active", "created_at")
    list_filter = ("plan", "is_active")
    search_fields = ("name", "slug", "admin__email", "admin__username")
    prepopulated_fields = {"slug": ("name",)}
    readonly_fields = ("created_at", "updated_at")
    inlines = [EnterpriseMembershipInline]


@admin.register(EnterpriseMembership, site=admin_site)
class EnterpriseMembershipAdmin(admin.ModelAdmin):
    list_display = ("enterprise", "creator", "is_active", "joined_at")
    list_filter = ("is_active",)
    search_fields = ("enterprise__name", "creator__display_name", "creator__slug")
    readonly_fields = ("joined_at",)
    raw_id_fields = ("enterprise", "creator")


@admin.register(FundDistribution, site=admin_site)
class FundDistributionAdmin(admin.ModelAdmin):
    list_display = ("reference", "enterprise", "total_amount", "distributed_by", "distributed_at")
    list_filter = ("enterprise",)
    search_fields = ("enterprise__name", "notes")
    readonly_fields = ("distributed_at",)
    date_hierarchy = "distributed_at"
    inlines = [FundDistributionItemInline]


@admin.register(FundDistributionItem, site=admin_site)
class FundDistributionItemAdmin(admin.ModelAdmin):
    list_display = ("distribution", "creator", "amount", "status", "paid_at")
    list_filter = ("status",)
    search_fields = ("creator__display_name", "reference")
    raw_id_fields = ("distribution", "creator")
    readonly_fields = ("distribution",)

    actions = ["mark_paid", "mark_failed"]

    @admin.action(description="Mark selected items as Paid")
    def mark_paid(self, request, queryset):
        from django.utils import timezone
        queryset.update(status=FundDistributionItem.Status.PAID, paid_at=timezone.now())
        self.message_user(request, f"{queryset.count()} item(s) marked as Paid.")

    @admin.action(description="Mark selected items as Failed")
    def mark_failed(self, request, queryset):
        queryset.update(status=FundDistributionItem.Status.FAILED)
        self.message_user(request, f"{queryset.count()} item(s) marked as Failed.")
