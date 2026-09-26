from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('creators', '0018_livestreamcomment_stream_livestreamgoal_stream'),
    ]

    operations = [
        # LiveStreamComment: moderation fields
        migrations.AddField(
            model_name='livestreamcomment',
            name='is_pinned',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='livestreamcomment',
            name='is_deleted',
            field=models.BooleanField(default=False),
        ),
        # LiveStream: viewer count
        migrations.AddField(
            model_name='livestream',
            name='viewer_count',
            field=models.PositiveIntegerField(default=0),
        ),
        # LiveStreamReaction
        migrations.CreateModel(
            name='LiveStreamReaction',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('reaction_type', models.CharField(
                    choices=[
                        ('heart', 'heart'), ('fire', 'fire'), ('clap', 'clap'),
                        ('wow', 'wow'), ('100', '100'), ('laugh', 'laugh'),
                    ],
                    max_length=20,
                )),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('stream', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='reactions',
                    to='creators.livestream',
                )),
            ],
            options={'ordering': ['-created_at']},
        ),
        # LiveStreamPoll
        migrations.CreateModel(
            name='LiveStreamPoll',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('question', models.CharField(max_length=300)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('stream', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='polls',
                    to='creators.livestream',
                )),
            ],
            options={'ordering': ['-created_at']},
        ),
        # LiveStreamPollOption
        migrations.CreateModel(
            name='LiveStreamPollOption',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('text', models.CharField(max_length=200)),
                ('vote_count', models.PositiveIntegerField(default=0)),
                ('poll', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='options',
                    to='creators.livestreampoll',
                )),
            ],
            options={'ordering': ['id']},
        ),
    ]
