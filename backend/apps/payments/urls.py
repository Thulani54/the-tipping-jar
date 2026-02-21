from django.urls import path
from .views import paystack_webhook, stripe_webhook

urlpatterns = [
    path("webhook/paystack/", paystack_webhook, name="paystack-webhook"),
    path("webhook/stripe/",   stripe_webhook,   name="stripe-webhook"),   # legacy
]
