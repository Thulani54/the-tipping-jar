from rest_framework import serializers

from .models import JobOpening


class JobOpeningSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobOpening
        fields = [
            "id", "title", "department", "location",
            "employment_type", "description", "created_at",
        ]
