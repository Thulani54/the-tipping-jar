from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.users.models import User


class RegisterLoginTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_register_fan(self):
        res = self.client.post(
            reverse("register"),
            {"username": "fan1", "email": "fan1@example.com", "password": "strongpass1", "role": "fan"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(User.objects.filter(email="fan1@example.com").exists())

    def test_register_creator(self):
        res = self.client.post(
            reverse("register"),
            {"username": "creator1", "email": "creator1@example.com", "password": "strongpass1", "role": "creator"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)

    def test_login_returns_tokens(self):
        User.objects.create_user(username="u", email="u@example.com", password="pass1234")
        res = self.client.post(
            reverse("token_obtain_pair"),
            {"email": "u@example.com", "password": "pass1234"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("access", res.data)
        self.assertIn("refresh", res.data)

    def test_me_requires_auth(self):
        res = self.client.get(reverse("me"))
        self.assertEqual(res.status_code, 401)
