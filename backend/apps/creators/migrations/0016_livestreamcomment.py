from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('creators', '0015_livestream'),
    ]

    operations = [
        migrations.CreateModel(
            name='LiveStreamComment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('username', models.CharField(max_length=60)),
                ('message', models.TextField(max_length=300)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('creator', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='live_comments',
                    to='creators.creatorprofile',
                )),
            ],
            options={
                'ordering': ['created_at'],
            },
        ),
    ]
