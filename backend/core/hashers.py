from django.contrib.auth.hashers import PBKDF2PasswordHasher


class TippingJarPasswordHasher(PBKDF2PasswordHasher):
    """
    PBKDF2 with a reduced iteration count.

    Django 5.0 defaults to 870,000 rounds — intentionally slow but brutal
    on a small container. 300,000 is still far above NIST SP 800-132
    recommendations and cuts hashing time by ~3×, making registration
    responsive without sacrificing meaningful security.

    Existing passwords hashed at 870k will still verify correctly (Django
    falls back to the legacy hasher); on next login they'll be auto-upgraded
    to 300k.
    """

    iterations = 300_000
