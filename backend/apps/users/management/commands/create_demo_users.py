from django.core.management.base import BaseCommand

from apps.users.models import User

DEMO_USERS = [
    {
        "email": "enterprise@tippingjar.co.za",
        "username": "demo_enterprise",
        "password": "TippingJar@Enterprise1",
        "role": User.Role.ENTERPRISE,
        "first_name": "Enterprise",
        "last_name": "Demo",
    },
    {
        "email": "creator@tippingjar.co.za",
        "username": "demo_creator",
        "password": "TippingJar@Creator1",
        "role": User.Role.CREATOR,
        "first_name": "Creator",
        "last_name": "Demo",
        "creator_profile": {
            "display_name": "Demo Creator",
            "slug": "demo-creator",
            "tagline": "Your favourite demo creator on TippingJar",
            "category": "music",
            "audience_size": "1k-10k",
        },
    },
    {
        "email": "fan@tippingjar.co.za",
        "username": "demo_fan",
        "password": "TippingJar@Fan1",
        "role": User.Role.FAN,
        "first_name": "Fan",
        "last_name": "Demo",
    },
]


def seed_demo_users(apps=None, schema_editor=None):
    """
    Create the 3 demo users. Idempotent — skips any that already exist.
    Can be called from a management command or a data migration RunPython.
    """
    if apps is not None:
        UserModel = apps.get_model("users", "User")
        CreatorProfileModel = apps.get_model("creators", "CreatorProfile")
        use_historical = True
    else:
        from apps.creators.models import CreatorProfile as CreatorProfileModel  # noqa: PLC0415
        UserModel = User
        use_historical = False

    for spec in DEMO_USERS:
        profile_spec = spec.get("creator_profile")

        if UserModel.objects.filter(email=spec["email"]).exists():
            continue

        if use_historical:
            user = UserModel(
                email=spec["email"],
                username=spec["username"],
                role=spec["role"],
                first_name=spec["first_name"],
                last_name=spec["last_name"],
            )
            user.set_password(spec["password"])
            user.save()
        else:
            user = UserModel.objects.create_user(
                email=spec["email"],
                username=spec["username"],
                password=spec["password"],
                role=spec["role"],
                first_name=spec["first_name"],
                last_name=spec["last_name"],
                two_fa_enabled=False,
            )

        if profile_spec:
            CreatorProfileModel.objects.get_or_create(
                user=user,
                defaults=profile_spec,
            )


def reverse_seed(apps, schema_editor):
    UserModel = apps.get_model("users", "User")
    emails = [s["email"] for s in DEMO_USERS]
    UserModel.objects.filter(email__in=emails).delete()


class Command(BaseCommand):
    help = "Create 3 demo users: enterprise, creator, and fan."

    def handle(self, *args, **options):
        seed_demo_users()
        self.stdout.write(self.style.SUCCESS("Demo users created (or already exist)."))
        self.stdout.write("  enterprise@tippingjar.co.za  /  TippingJar@Enterprise1")
        self.stdout.write("  creator@tippingjar.co.za     /  TippingJar@Creator1")
        self.stdout.write("  fan@tippingjar.co.za         /  TippingJar@Fan1")
