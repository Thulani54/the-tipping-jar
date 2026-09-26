from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('creators', '0017_livestreamcomment_extras_livestreamgoal'),
    ]

    operations = [
        migrations.AddField(
            model_name='livestreamcomment',
            name='stream',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='comments',
                to='creators.livestream',
            ),
        ),
        migrations.AddField(
            model_name='livestreamgoal',
            name='stream',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='goals',
                to='creators.livestream',
            ),
        ),
    ]
