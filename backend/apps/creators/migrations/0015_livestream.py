from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('creators', '0014_creatorprofile_paystack_split_code'),
    ]

    operations = [
        migrations.CreateModel(
            name='LiveStream',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('room_name', models.CharField(max_length=200)),
                ('title', models.CharField(blank=True, default='', max_length=200)),
                ('is_live', models.BooleanField(default=True)),
                ('started_at', models.DateTimeField(auto_now_add=True)),
                ('ended_at', models.DateTimeField(blank=True, null=True)),
                ('creator', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='live_streams',
                    to='creators.creatorprofile',
                )),
            ],
            options={
                'ordering': ['-started_at'],
            },
        ),
    ]
