#!/bin/sh

echo "=== TippingJar Backend Starting ==="
echo "DATABASE_URL set: $([ -n "$DATABASE_URL" ] && echo yes || echo NO)"
echo "SECRET_KEY set:   $([ -n "$SECRET_KEY" ] && echo yes || echo NO)"

echo "Running database migrations..."
python manage.py migrate --noinput
MIGRATE_EXIT=$?

if [ $MIGRATE_EXIT -ne 0 ]; then
    echo "WARNING: Migrations failed (exit $MIGRATE_EXIT) — starting gunicorn anyway"
fi

echo "Starting gunicorn..."
exec gunicorn core.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 5 \
    --threads 2 \
    --worker-class gthread \
    --timeout 120 \
    --keep-alive 65 \
    --access-logfile - \
    --error-logfile -
