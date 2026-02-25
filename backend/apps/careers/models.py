from django.db import models


class JobOpening(models.Model):
    class EmploymentType(models.TextChoices):
        FULL_TIME = "Full-time", "Full-time"
        PART_TIME = "Part-time", "Part-time"
        CONTRACT = "Contract", "Contract"
        INTERNSHIP = "Internship", "Internship"

    class Department(models.TextChoices):
        ENGINEERING = "Engineering", "Engineering"
        DESIGN = "Design", "Design"
        GROWTH = "Growth", "Growth"
        OPERATIONS = "Operations", "Operations"
        MARKETING = "Marketing", "Marketing"
        PRODUCT = "Product", "Product"
        FINANCE = "Finance", "Finance"
        OTHER = "Other", "Other"

    title = models.CharField(max_length=200)
    department = models.CharField(
        max_length=30, choices=Department.choices, default=Department.ENGINEERING
    )
    location = models.CharField(
        max_length=100, default="Remote",
        help_text='e.g. "Remote", "Cape Town, ZA", "Remote (Africa)"',
    )
    employment_type = models.CharField(
        max_length=20, choices=EmploymentType.choices, default=EmploymentType.FULL_TIME
    )
    description = models.TextField(
        blank=True,
        help_text="Full job description. Supports HTML from the rich-text editor.",
    )
    is_active = models.BooleanField(default=True, help_text="Show this role on the careers page.")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["department", "title"]
        verbose_name = "Job Opening"
        verbose_name_plural = "Job Openings"

    def __str__(self):
        return f"{self.title} ({self.department})"
