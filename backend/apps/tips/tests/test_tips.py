from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.models import User
from apps.creators.models import CreatorProfile
from apps.tips.models import Tip
from unittest.mock import patch


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

    @patch("apps.tips.views.stripe.PaymentIntent.create")
    def test_initiate_tip(self, mock_create):
        mock_create.return_value = type("obj", (object,), {"id": "pi_test", "client_secret": "secret_test"})()
        res = self.client.post(
            reverse("initiate-tip"),
            {"creator_slug": "creator-slug", "amount": "5.00", "tipper_name": "Fan"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("client_secret", res.data)
        self.assertTrue(Tip.objects.filter(stripe_payment_intent_id="pi_test").exists())
