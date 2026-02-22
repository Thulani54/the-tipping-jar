from django.conf import settings
from django.conf.urls.static import static
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from apps.users.jwt import TippingJarTokenView
from core.admin_site import admin_site

urlpatterns = [
    path("admin/", admin_site.urls),
    # Auth
    path("api/auth/token/", TippingJarTokenView.as_view(), name="token_obtain_pair"),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    # Apps
    path("api/users/", include("apps.users.urls")),
    path("api/creators/", include("apps.creators.urls")),
    path("api/tips/", include("apps.tips.urls")),
    path("api/payments/", include("apps.payments.urls")),
    path("api/support/",  include("apps.support.urls")),
    path("api/enterprise/", include("apps.enterprise.urls")),
    path("api/platform/",  include("apps.platform.urls")),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
