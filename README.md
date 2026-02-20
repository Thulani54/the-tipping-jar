# The Tipping Jar

A creator tipping platform — fans send tips directly to content creators and freelancers.

## Stack

| Layer     | Technology                        |
|-----------|-----------------------------------|
| Backend   | Python · Django REST Framework    |
| Database  | PostgreSQL                        |
| Container | Docker · Docker Compose           |
| Frontend  | Flutter Web                       |

## Monorepo structure

```
the-tipping-jar/
├── backend/          # Django REST API
│   ├── core/         # Django project settings
│   ├── apps/
│   │   ├── users/    # Auth, profiles
│   │   ├── creators/ # Creator pages & wallets
│   │   └── tips/     # Tip transactions
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/         # Flutter Web app
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       └── services/
├── docker-compose.yml
└── README.md
```

## Quick start (backend)

```bash
cp backend/.env.example backend/.env   # fill in secrets
docker compose up --build
```

API will be available at `http://localhost:8000/api/`

## Quick start (frontend)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```
