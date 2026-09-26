from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('creators', '0016_livestreamcomment'),
    ]

    operations = [
        migrations.AddField(
            model_name='livestreamcomment',
            name='is_creator',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='livestreamcomment',
            name='msg_type',
            field=models.CharField(
                choices=[('text', 'Text'), ('gift', 'Gift'), ('image', 'Image'), ('thank_you', 'Thank You')],
                default='text', max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='livestreamcomment',
            name='gift_type',
            field=models.CharField(blank=True, default='', max_length=30),
        ),
        migrations.AddField(
            model_name='livestreamcomment',
            name='image_url',
            field=models.URLField(blank=True, default=''),
        ),
        migrations.AlterField(
            model_name='livestreamcomment',
            name='message',
            field=models.TextField(blank=True, default='', max_length=500),
        ),
        migrations.CreateModel(
            name='LiveStreamGoal',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=200)),
                ('target_amount', models.DecimalField(decimal_places=2, max_digits=10)),
                ('current_amount', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('creator', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                                              related_name='live_goals', to='creators.creatorprofile')),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
