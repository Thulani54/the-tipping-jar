from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.models import User
from apps.creators.models import CreatorProfile


class CreatorTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username="creator", email="c@example.com", password="pass1234", role="creator"
        )
        self.profile = CreatorProfile.objects.create(
            user=self.user, display_name="Cool Creator", slug="cool-creator"
        )

    def test_list_creators(self):
        res = self.client.get(reverse("creator-list"))
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["results"][0]["slug"], "cool-creator")

    def test_creator_detail(self):
        res = self.client.get(reverse("creator-detail", kwargs={"slug": "cool-creator"}))
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["display_name"], "Cool Creator")

    def test_unknown_creator_404(self):
        res = self.client.get(reverse("creator-detail", kwargs={"slug": "nobody"}))
        self.assertEqual(res.status_code, 404)
