from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.creators.models import CreatorProfile
from apps.tips.models import Tip
from apps.users.models import User


class TipTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username="creator", email="c@example.com", password="pass1234"
        )
        self.profile = CreatorProfile.objects.create(
            user=self.user, display_name="Creator", slug="creator-slug"
        )

    def test_tip_feed_empty(self):
        res = self.client.get(reverse("creator-tips", kwargs={"slug": "creator-slug"}))
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["results"], [])

    def test_tip_feed_shows_completed_only(self):
        Tip.objects.create(
            creator=self.profile, tipper_name="Fan", amount=5, status=Tip.Status.PENDING
        )
        Tip.objects.create(
            creator=self.profile, tipper_name="Fan2", amount=10, status=Tip.Status.COMPLETED
        )
        res = self.client.get(reverse("creator-tips", kwargs={"slug": "creator-slug"}))
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data["results"]), 1)
        self.assertEqual(res.data["results"][0]["tipper_name"], "Fan2")

    def test_initiate_tip_dev_mode(self):
        """In dev mode (no PAYSTACK_SECRET_KEY), tip is created immediately as COMPLETED."""
        res = self.client.post(
            reverse("initiate-tip"),
            {"creator_slug": "creator-slug", "amount": "5.00", "tipper_name": "Fan"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(res.data.get("dev_mode"))
        self.assertIn("tip_id", res.data)
        self.assertTrue(
            Tip.objects.filter(id=res.data["tip_id"], status=Tip.Status.COMPLETED).exists()
        )
