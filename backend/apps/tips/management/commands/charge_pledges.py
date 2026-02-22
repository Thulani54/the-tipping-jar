"""
Management command: charge_pledges

Finds active Pledges whose next_charge_date is today or past,
re-charges them via Paystack charge_authorization, creates a new Tip,
and updates next_charge_date += 30 days.

Usage:
    python manage.py charge_pledges

Schedule this command daily via cron or Celery Beat in production.
"""
import datetime
import logging
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.payments import paystack as ps
from apps.tips.models import Pledge, Tip

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Charge active pledges whose next_charge_date is due today or earlier."

    def handle(self, *args, **options):
        today = datetime.date.today()
        due_pledges = Pledge.objects.filter(
            status=Pledge.Status.ACTIVE,
            next_charge_date__lte=today,
            paystack_authorization_code__gt="",
        ).select_related("creator", "fan")

        self.stdout.write(f"Found {due_pledges.count()} due pledge(s).")

        for pledge in due_pledges:
            email = pledge.paystack_email or (pledge.fan.email if pledge.fan else "")
            if not email:
                self.stderr.write(f"  Pledge {pledge.id}: no email — skipping.")
                continue

            reference = ps.generate_reference()
            try:
                tx = ps.charge_authorization(
                    email=email,
                    amount_zar=float(pledge.amount),
                    authorization_code=pledge.paystack_authorization_code,
                    reference=reference,
                )
            except RuntimeError as exc:
                self.stderr.write(f"  Pledge {pledge.id} charge failed: {exc}")
                pledge.status = Pledge.Status.PAUSED
                pledge.save(update_fields=["status"])
                continue

            # Create a completed tip for this pledge charge
            fees = ps.calculate_fees(float(pledge.amount))
            tip = Tip.objects.create(
                creator=pledge.creator,
                tipper=pledge.fan,
                tipper_name=pledge.fan_name,
                tipper_email=email,
                amount=pledge.amount,
                message=f"Monthly pledge — {pledge.creator.display_name}",
                status=Tip.Status.COMPLETED,
                paystack_reference=reference,
                paystack_authorization_code=pledge.paystack_authorization_code,
                platform_fee=Decimal(str(fees["platform_fee"])),
                service_fee=Decimal(str(fees["service_fee"])),
                creator_net=Decimal(str(fees["creator_net"])),
            )

            # Advance next charge date
            pledge.next_charge_date = today + datetime.timedelta(days=30)
            pledge.save(update_fields=["next_charge_date"])

            self.stdout.write(
                f"  Pledge {pledge.id}: charged R{pledge.amount} → tip {tip.id}, "
                f"next charge {pledge.next_charge_date}."
            )
