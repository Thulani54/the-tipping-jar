import json

from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt

from apps.tips.models import Tip
from apps.payments import paystack as ps
from apps.support.emails import send_tip_thank_you


@csrf_exempt
def paystack_webhook(request):
    """
    Handle incoming Paystack webhook events.

    Paystack signs each request with HMAC-SHA512.
    Verified events update Tip records accordingly.

    Key events handled:
        charge.success   → Tip completed
        charge.failed    → Tip failed
        refund.processed → Tip refunded
    """
    payload = request.body
    signature = request.META.get("HTTP_X_PAYSTACK_SIGNATURE", "")

    if not ps.verify_webhook_signature(payload, signature):
        return HttpResponse(status=400)

    try:
        event = json.loads(payload)
    except (ValueError, KeyError):
        return HttpResponse(status=400)

    event_type = event.get("event", "")
    data = event.get("data", {})
    reference = data.get("reference", "")

    if not reference:
        return HttpResponse(status=200)

    if event_type == "charge.success":
        tip = Tip.objects.filter(paystack_reference=reference).first()
        if tip and tip.status != Tip.Status.COMPLETED:
            tip.status = Tip.Status.COMPLETED
            tip.save(update_fields=["status"])
            send_tip_thank_you(tip)

    elif event_type == "charge.failed":
        Tip.objects.filter(paystack_reference=reference).update(
            status=Tip.Status.FAILED
        )

    elif event_type == "refund.processed":
        Tip.objects.filter(paystack_reference=reference).update(
            status=Tip.Status.REFUNDED
        )

    return HttpResponse(status=200)


@csrf_exempt
def stripe_webhook(request):
    """
    Legacy Stripe webhook — kept for backward compatibility.
    No new tips use Stripe; this only handles any lingering Stripe payments.
    """
    import stripe
    from django.conf import settings

    stripe.api_key = settings.STRIPE_SECRET_KEY
    if not stripe.api_key:
        return HttpResponse(status=200)

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
