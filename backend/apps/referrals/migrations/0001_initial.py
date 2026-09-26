import apps.referrals.models
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ReferralCode',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('code', models.CharField(default=apps.referrals.models._gen_code, max_length=20, unique=True)),
                ('commission_rate', models.DecimalField(decimal_places=4, default=0.01, help_text='Fraction of tips earned by referred creator paid to referrer. 0.01 = 1 %.', max_digits=5)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('owner', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='referral_code_obj', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='Referral',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('commission_rate', models.DecimalField(decimal_places=4, max_digits=5)),
                ('commission_months', models.PositiveSmallIntegerField(default=6)),
                ('expires_at', models.DateTimeField()),
                ('status', models.CharField(choices=[('pending', 'Pending Bank Details'), ('active', 'Active'), ('expired', 'Expired')], default='pending', max_length=10)),
                ('bank_name', models.CharField(blank=True, max_length=100)),
                ('bank_account_name', models.CharField(blank=True, max_length=150)),
                ('bank_account_number', models.CharField(blank=True, max_length=30)),
                ('bank_details_submitted_at', models.DateTimeField(blank=True, null=True)),
                ('signed_up_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('referral_code', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='referrals', to='referrals.referralcode')),
                ('referred_user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='referral_record', to=settings.AUTH_USER_MODEL)),
                ('referrer', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='referrals_made', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-signed_up_at'],
            },
        ),
    ]
