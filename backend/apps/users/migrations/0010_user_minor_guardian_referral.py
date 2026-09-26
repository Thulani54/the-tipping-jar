from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0009_user_gender_dob'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='is_minor',
            field=models.BooleanField(default=False, help_text='True when the account is managed by a parent or guardian on behalf of a minor.'),
        ),
        migrations.AddField(
            model_name='user',
            name='guardian_name',
            field=models.CharField(blank=True, help_text='Full name of parent / guardian (required when is_minor=True).', max_length=200),
        ),
        migrations.AddField(
            model_name='user',
            name='guardian_email',
            field=models.EmailField(blank=True, help_text="Guardian's email address for account communications."),
        ),
        migrations.AddField(
            model_name='user',
            name='guardian_phone',
            field=models.CharField(blank=True, help_text="Guardian's phone number.", max_length=20),
        ),
        migrations.AddField(
            model_name='user',
            name='referral_code_used',
            field=models.CharField(blank=True, help_text='The referral code entered by this user at signup.', max_length=20),
        ),
    ]
