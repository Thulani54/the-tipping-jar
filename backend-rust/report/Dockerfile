FROM python:3.12-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1 TZ=Africa/Johannesburg

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY daily_report.py .

# Run once and exit — invoked nightly by cron via `docker compose run`.
ENTRYPOINT ["python", "daily_report.py"]
