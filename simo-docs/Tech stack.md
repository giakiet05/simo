# Dev
- Backend: Go 
- DB: Postgres 
- Frontend: Flutter
- Event Bus: Go channels -> Redis Pub/Sub -> Message Queue (Start simple, then upgrade)
- Job scheduler: Go lib (gocron)
- Auth: Google OAuth
# Deploy
- Backend: Coolify / Homeserver (Docker)
- Postgres: PostgreSQL (Self-hosted on Homeserver)
- Web: Coolify / Homeserver