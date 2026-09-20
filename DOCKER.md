# Docker Development and Deployment

## Local Development

### Prerequisites
- Docker Desktop (or Docker + Docker Compose)

### Quick Start

```bash
docker compose up --build
```

This starts:
- **PostgreSQL** (host port 5433 → container 5432) — creates `meal_planner_development` database
- **Rails backend** (port 3000) — creates the database, runs migrations, seeds it, then starts the dev server
- **Vite frontend** (port 5173) — starts dev server with hot-module reloading

### Access

- Frontend: http://127.0.0.1:5173
- Backend API: http://127.0.0.1:3000
- Database: postgresql://postgres:postgres@127.0.0.1:5433/meal_planner_development

### Common Commands

```bash
# View logs
docker compose logs -f

# Stop services
docker compose down

# Restart backend (after Gemfile changes)
docker compose build backend && docker compose up backend

# Run Rails console
docker compose exec backend rails console

# Run frontend tests
docker compose exec frontend pnpm test

# Re-run seeds manually
docker compose exec backend rails db:seed
```

## Services

| Service | Image | Port | Dockerfile |
| --- | --- | --- | --- |
| postgres | postgres:16-alpine | 5433:5432 | (standard) |
| backend | ruby:3.3.8-slim | 3000 | Dockerfile.dev |
| frontend | node:22-alpine | 5173 | Dockerfile.dev |

## Volumes

Source code is bind-mounted directly (not copied into the image), so edits on
the host are picked up without rebuilding:

| Mount | Purpose |
| --- | --- |
| `postgres_data` (named volume) | Database persistence |
| `./backend:/rails` | Live backend source for the dev server |
| `./frontend/src:/app/src`, `./frontend/public:/app/public` | Live frontend source for Vite HMR |

## Production Builds

### Frontend

```bash
docker build \
  --build-arg VITE_API_BASE_URL=https://api.example.com \
  -t meal-planner-frontend:latest \
  frontend

docker run -p 8080:8080 meal-planner-frontend:latest
```

The image serves static assets via Nginx with proper caching headers.

### Backend

```bash
docker build -t meal-planner-backend:latest backend

docker run -d \
  -p 80:80 \
  -e RAILS_ENV=production \
  -e RAILS_MASTER_KEY=<value> \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  -e FRONTEND_ORIGIN=https://your-frontend.com \
  meal-planner-backend:latest
```

## Troubleshooting

**Port already in use?**
```bash
lsof -i :3000
kill -9 <PID>
```

**HMR not working?**
- Check logs: `docker compose logs frontend`
- On WSL2, use `127.0.0.1:5173` instead of `localhost:5173`

**Database won't connect?**
```bash
docker compose logs postgres
docker compose down -v
docker compose up --build
```

**Gems not updating?**
```bash
docker compose build backend
docker compose up backend
```

## Notes

- First run takes 2-3 minutes to build, migrate, and seed the database
- Source code is mounted as a volume for live reload
- Dev Dockerfiles (Dockerfile.dev) include dev/test gems
- Production Dockerfiles are optimized with multi-stage builds
