import datetime
import json

from django.http import HttpResponse
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt

from apps.creators.models import CreatorNotification
from apps.payments import paystack as ps
from apps.support.emails import (
    send_first_thousand_email,
    send_first_tip_email,
    send_tip_thank_you,
)
from apps.tips.models import Tip


def _update_streak(tip: Tip) -> None:
    """Create or update TipStreak for the tipper after a completed tip."""
    from apps.tips.models import TipStreak

    creator = tip.creator
    fan = tip.tipper
    fan_email = (tip.tipper_email or "").lower()
    if not fan and not fan_email:
        return

    today = datetime.date.today()
    this_month_start = today.replace(day=1)
    prev_month = (this_month_start - datetime.timedelta(days=1)).replace(day=1)

    # Find existing streak
    streak = None
    if fan:
        streak = TipStreak.objects.filter(fan=fan, creator=creator).first()
    if streak is None and fan_email:
        streak = TipStreak.objects.filter(fan_email=fan_email, creator=creator).first()

    badge_thresholds = {2: "2month", 3: "3month", 6: "6month", 12: "12month"}

    if streak is None:
        TipStreak.objects.create(
            fan=fan,
            fan_email=fan_email,
            creator=creator,
            current_streak=1,
            max_streak=1,
            last_tip_month=this_month_start,
            badges=[],
        )
        return

    # Already counted this month
    if streak.last_tip_month >= this_month_start:
        return

    if streak.last_tip_month >= prev_month:
        # Consecutive month — increment
        streak.current_streak += 1
        if streak.current_streak > streak.max_streak:
            streak.max_streak = streak.current_streak
        # Award badges
        for threshold, badge in badge_thresholds.items():
            if streak.current_streak >= threshold and badge not in streak.badges:
                streak.badges.append(badge)
    else:
        # Streak broken — reset
        streak.current_streak = 1

    streak.last_tip_month = this_month_start
    streak.save(update_fields=["current_streak", "max_streak", "last_tip_month", "badges"])


def _check_milestones(tip: Tip) -> None:
    """Check if any active milestone goals have been crossed this month."""
    from django.db.models import Sum

    from apps.creators.models import MilestoneGoal

    creator = tip.creator
    today = datetime.date.today()
    month_total = Tip.objects.filter(
        creator=creator,
        status=Tip.Status.COMPLETED,
        created_at__year=today.year,
        created_at__month=today.month,
    ).aggregate(t=Sum("amount"))["t"] or 0

    for milestone in MilestoneGoal.objects.filter(
        creator=creator, is_active=True, is_achieved=False
    ):
        if month_total >= milestone.target_amount:
            milestone.is_achieved = True
            milestone.achieved_at = timezone.now()
            milestone.save(update_fields=["is_achieved", "achieved_at"])


def _update_pledge(tip: Tip) -> None:
    """After a completed tip, set next_charge_date on active pledges for this fan+creator."""
    from apps.tips.models import Pledge

    fan = tip.tipper
    if not fan:
        return
    Pledge.objects.filter(
        fan=fan, creator=tip.creator, status=Pledge.Status.ACTIVE
    ).update(
        next_charge_date=datetime.date.today() + datetime.timedelta(days=30)
    )


def _fire_tip_notifications(tip: Tip) -> None:
    """
    After a tip is confirmed as COMPLETED:
    - Create in-app TIP_RECEIVED notification
    - If first tip → create FIRST_TIP notification + email
    - If total crosses R1 000 → create FIRST_THOUSAND notification + email (once)
    """
    creator = tip.creator

    # Always: in-app tip-received notification
    tipper = tip.tipper_name or "Anonymous"
    CreatorNotification.objects.create(
        creator=creator,
        notification_type=CreatorNotification.Type.TIP_RECEIVED,
        title=f"New tip — R{tip.amount:.2f} from {tipper}",
        message=(
            f"{tipper} sent you R{tip.amount:.2f}."
            + (f" Message: \"{tip.message[:120]}\"" if tip.message else "")
        ),
    )

    completed_tips = creator.tips.filter(status="completed")
    completed_count = completed_tips.count()

    # First tip ever
    if completed_count == 1:
        CreatorNotification.objects.create(
            creator=creator,
            notification_type=CreatorNotification.Type.FIRST_TIP,
            title="You got your first tip! 🎉",
            message=f"Congratulations! {tipper} just sent you your first tip of R{tip.amount:.2f}.",
        )
        send_first_tip_email(creator, tip)

    # R1 000 milestone — fire only the first time total crosses 1000
    from django.db.models import Sum
    total = completed_tips.aggregate(t=Sum("amount"))["t"] or 0
    prev_total = total - tip.amount
    if prev_total < 1000 <= total:
        already_notified = creator.notifications.filter(
            notification_type=CreatorNotification.Type.FIRST_THOUSAND
        ).exists()
        if not already_notified:
            CreatorNotification.objects.create(
                creator=creator,
                notification_type=CreatorNotification.Type.FIRST_THOUSAND,
                title="You've earned R1 000! 💰",
                message="You just crossed R1 000 in total tips. Amazing milestone — keep going!",
            )
            send_first_thousand_email(creator)


@csrf_exempt
def paystack_webhook(request):
    """
    Handle incoming Paystack webhook events.

    Paystack signs each request with HMAC-SHA512.
    Verified events update Tip records accordingly.

    Key events handled:
        charge.success   → Tip completed; stores auth code, updates streak, checks milestones
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
        auth_code = data.get("authorization", {}).get("authorization_code", "")
        # Atomic update — only process if still pending (avoids race with VerifyTipView)
        rows = Tip.objects.filter(
            paystack_reference=reference, status=Tip.Status.PENDING
        ).update(status=Tip.Status.COMPLETED, paystack_authorization_code=auth_code)
        if rows:
            tip = Tip.objects.filter(paystack_reference=reference).first()
            if tip:
                send_tip_thank_you(tip)
                _update_streak(tip)
                _check_milestones(tip)
                _update_pledge(tip)
                _fire_tip_notifications(tip)

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
