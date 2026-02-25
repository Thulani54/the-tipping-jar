from django.contrib import admin
from django_summernote.admin import SummernoteModelAdmin

from core.admin_site import admin_site

from .models import JobOpening


@admin.register(JobOpening, site=admin_site)
class JobOpeningAdmin(SummernoteModelAdmin):
    summernote_fields = ("description",)

    list_display = ("title", "department", "location", "employment_type", "is_active", "created_at")
    list_filter = ("is_active", "department", "employment_type")
    search_fields = ("title", "department")
    list_editable = ("is_active",)
    readonly_fields = ("created_at", "updated_at")

    fieldsets = (
        (
            "Role Details",
            {
                "fields": (
                    "title", "department", "location",
                    "employment_type", "is_active",
                )
            },
        ),
        (
            "Description",
            {
                "fields": ("description",),
                "description": "Full job description with responsibilities, requirements, and benefits.",
            },
        ),
        (
            "Timestamps",
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )
