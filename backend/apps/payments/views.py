import stripe
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse
from apps.tips.models import Tip

stripe.api_key = settings.STRIPE_SECRET_KEY


@csrf_exempt
def stripe_webhook(request):
    payload = request.body
    sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except (ValueError, stripe.error.SignatureVerificationError):
        return HttpResponse(status=400)

    if event["type"] == "payment_intent.succeeded":
        intent = event["data"]["object"]
        Tip.objects.filter(stripe_payment_intent_id=intent["id"]).update(
            status=Tip.Status.COMPLETED
        )

    elif event["type"] == "payment_intent.payment_failed":
        intent = event["data"]["object"]
        Tip.objects.filter(stripe_payment_intent_id=intent["id"]).update(
            status=Tip.Status.FAILED
        )

    return HttpResponse(status=200)
