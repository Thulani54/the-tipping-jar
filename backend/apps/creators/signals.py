"""
Django signals for creator lifecycle events.

Handles: welcome notification/email on profile creation,
first-jar notification/email on first jar creation.

Tip-related events (first tip, R1 000 milestone) are fired from
payments/views.py after charge.success webhook processing.
"""
import logging

from django.db.models.signals import post_save
from django.dispatch import receiver

logger = logging.getLogger(__name__)


@receiver(post_save, sender="creators.CreatorProfile")
def on_creator_profile_created(sender, instance, created, **kwargs):
    if not created:
        return
    from apps.support.emails import send_creator_welcome

    from .models import CreatorNotification

    CreatorNotification.objects.create(
        creator=instance,
        notification_type=CreatorNotification.Type.WELCOME,
        title="Welcome to TippingJar! 🎉",
        message=(
            "Your creator page is live. Share it with your fans to start receiving tips. "
            "Add your bank details in the dashboard to enable payouts."
        ),
    )
    send_creator_welcome(instance)


@receiver(post_save, sender="creators.Jar")
def on_jar_created(sender, instance, created, **kwargs):
    if not created:
        return
    creator = instance.creator
    # Only fire for the very first jar
    if creator.jars.count() != 1:
        return

    from apps.support.emails import send_first_jar_email

    from .models import CreatorNotification

    CreatorNotification.objects.create(
        creator=creator,
        notification_type=CreatorNotification.Type.FIRST_JAR,
        title=f"First jar '{instance.name}' created! 🫙",
        message=(
            f"Your '{instance.name}' jar is live. Share your page so fans can "
            "tip directly into this jar."
        ),
    )
    send_first_jar_email(creator, instance)
