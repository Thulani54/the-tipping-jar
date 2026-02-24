from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(DEBUG=(bool, False))
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("SECRET_KEY", default="dev-secret-key-change-in-prod")
DEBUG = env("DEBUG")
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Third-party
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    # Local apps
    "apps.users",
    "apps.creators",
    "apps.tips",
    "apps.payments",
    "apps.support",
    "apps.enterprise",
    "apps.platform",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "core.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "core.wsgi.application"

import dj_database_url

_db_url = env("DATABASE_URL", default="")
if _db_url:
    DATABASES = {"default": dj_database_url.parse(_db_url, conn_max_age=600)}
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": env("DB_NAME", default="tipping_jar"),
            "USER": env("DB_USER", default="postgres"),
            "PASSWORD": env("DB_PASSWORD", default="postgres"),
            "HOST": env("DB_HOST", default="db"),
            "PORT": env("DB_PORT", default="5432"),
        }
    }

AUTH_USER_MODEL = "users.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# Reduce PBKDF2 iterations from Django 5's default 870k → 300k.
# Still > 30× above NIST minimum; ~3× faster on small containers.
# Legacy passwords (870k) still verify; they're auto-upgraded on next login.
PASSWORD_HASHERS = [
    "core.hashers.TippingJarPasswordHasher",
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "mediafiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# ── REST Framework ────────────────────────────────────────────────
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        # Platform key checked first (X-Platform-Key header)
        "apps.platform.authentication.PlatformKeyAuthentication",
        # API key (tj_live_sk_v1_...) checked second
        "apps.users.authentication.ApiKeyAuthentication",
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}

# ── JWT ───────────────────────────────────────────────────────────
from datetime import timedelta

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=1),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
}

# ── CORS ──────────────────────────────────────────────────────────
CORS_ALLOWED_ORIGINS = env.list(
    "CORS_ALLOWED_ORIGINS",
    default=[
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8080",
    ],
)

# ── Stripe (legacy — kept for backward compat) ────────────────────
STRIPE_SECRET_KEY = env("STRIPE_SECRET_KEY", default="")
STRIPE_WEBHOOK_SECRET = env("STRIPE_WEBHOOK_SECRET", default="")

# ── Paystack ──────────────────────────────────────────────────────
PAYSTACK_SECRET_KEY = env("PAYSTACK_SECRET_KEY", default="")
PAYSTACK_WEBHOOK_SECRET = env("PAYSTACK_WEBHOOK_SECRET", default="")
# Platform fee taken from every tip (goes to TippingJar master account)
PLATFORM_FEE_PERCENT = env.float("PLATFORM_FEE_PERCENT", default=3.0)
# Service fee charged to creator (Paystack's own processing fee share)
SERVICE_FEE_PERCENT = env.float("SERVICE_FEE_PERCENT", default=3.0)

# ── Email ──────────────────────────────────────────────────────────────────────
EMAIL_BACKEND      = env("EMAIL_BACKEND", default="django.core.mail.backends.smtp.EmailBackend")
EMAIL_HOST         = env("EMAIL_HOST", default="mail.tippingjar.co.za")
EMAIL_PORT         = env.int("EMAIL_PORT", default=587)
EMAIL_USE_TLS      = env.bool("EMAIL_USE_TLS", default=True)
EMAIL_HOST_USER    = env("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = env("EMAIL_HOST_PASSWORD", default="")
EMAIL_TIMEOUT      = 8  # seconds — prevents SMTP from blocking requests indefinitely

DEFAULT_FROM_EMAIL = env("DEFAULT_FROM_EMAIL", default="accounts@tippingjar.co.za")
NO_REPLY_EMAIL     = env("NO_REPLY_EMAIL",     default="no-reply@tippingjar.co.za")
SUPPORT_EMAIL      = env("SUPPORT_EMAIL",      default="support@tippingjar.co.za")

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {"class": "logging.StreamHandler"},
    },
    "loggers": {
        "apps": {"handlers": ["console"], "level": "INFO", "propagate": False},
    },
}

# ── SMS Portal ─────────────────────────────────────────────────────────────────
SMS_PORTAL_USERNAME = env("SMS_PORTAL_USERNAME", default="")
SMS_PORTAL_PASSWORD = env("SMS_PORTAL_PASSWORD", default="")
SMS_PORTAL_ENDPOINT = env("SMS_PORTAL_ENDPOINT", default="https://api.smsportal.com/api5/http5.aspx")

# ── Site ───────────────────────────────────────────────────────────────────────
SITE_URL = env("SITE_URL", default="https://tippingjar.co.za")

# ── Azure Blob Storage (media files) ───────────────────────────────────────────
AZURE_ACCOUNT_NAME = env("AZURE_STORAGE_ACCOUNT_NAME", default="")
AZURE_ACCOUNT_KEY  = env("AZURE_STORAGE_ACCOUNT_KEY", default="")
AZURE_CONTAINER    = env("AZURE_STORAGE_CONTAINER", default="media")

if AZURE_ACCOUNT_NAME:
    DEFAULT_FILE_STORAGE = "storages.backends.azure_storage.AzureStorage"
# else: falls back to local filesystem (dev)
