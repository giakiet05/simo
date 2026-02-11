# Dev
- Backend: Go 
- DB: Postgres 
- Frontend: Flutter
- Event Bus: Go channels -> Redis Pub/Sub -> Message Queue (Start simple, then upgrade)
- Job scheduler: Go lib (gocron)
- Auth: Google OAuth
# Deploy
- Backend: Render
- Postgres: Supabase (500MB free)
- Web: Vercel (better than Render)