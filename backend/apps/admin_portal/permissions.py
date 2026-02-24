from rest_framework.permissions import BasePermission


class IsAdminUser(BasePermission):
    """Allows access only to users with role == 'admin'."""

    message = "You do not have permission to access the admin portal."

    def has_permission(self, request, view):
        return (
            request.user is not None
            and request.user.is_authenticated
            and getattr(request.user, "is_admin", False)
        )
