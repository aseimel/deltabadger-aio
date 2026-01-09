# Deltabadger AIO (All-in-One)

Single container deployment of Deltabadger with embedded PostgreSQL, Redis, and all application services.

## Quick Start

```bash
docker run -d \
  --name deltabadger \
  -p 3000:3000 \
  -v deltabadger-data:/data \
  ghcr.io/aseimel/deltabadger-aio:latest
```

Access the app at http://localhost:3000

## First Run

On first run, the container will automatically:
1. Generate secure secrets (SECRET_KEY_BASE, DEVISE_SECRET_KEY, APP_ENCRYPTION_KEY)
2. Initialize PostgreSQL database cluster
3. Create the Rails database and load schema
4. Start all services (PostgreSQL, Redis, Rails, Sidekiq)

Secrets are persisted in `/data/secrets/.env.secrets` and will be reused on restart.

## Data Persistence

All data is stored in a single volume mounted at `/data`:

```
/data/
├── postgresql/data/    # PostgreSQL database files
├── redis/              # Redis AOF persistence
├── app/storage/        # Rails ActiveStorage files (uploads)
└── secrets/            # Auto-generated secrets
    ├── .env.secrets    # SECRET_KEY_BASE, DEVISE_SECRET_KEY, etc.
    └── .db_initialized # Flag indicating DB was set up
```

## Environment Variables

All variables are optional - the container works with sensible defaults.

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ROOT_URL` | `http://localhost:3000` | Application URL (for emails/links) |
| `HOME_PAGE_URL` | `http://localhost:3000` | Home page URL |
| `SMTP_ADDRESS` | `localhost` | SMTP server address |
| `SMTP_PORT` | `25` | SMTP server port |
| `SMTP_USER_NAME` | (empty) | SMTP username |
| `SMTP_PASSWORD` | (empty) | SMTP password |
| `NOTIFICATIONS_SENDER` | `noreply@localhost` | From address for emails |
| `ORDERS_FREQUENCY_LIMIT` | `60` | Minimum seconds between orders |
| `RAILS_MAX_THREADS` | `5` | Puma threads per worker |
| `WEB_CONCURRENCY` | (auto) | Puma workers (defaults to CPU cores) |

### Overriding Secrets (Advanced)

You can override auto-generated secrets via environment variables:
- `SECRET_KEY_BASE` - Rails session encryption
- `DEVISE_SECRET_KEY` - Authentication key
- `APP_ENCRYPTION_KEY` - API key encryption (16 hex chars)

**Warning**: Changing secrets after data exists will break encrypted fields (API keys)!

## Health Check

The container includes a health check that verifies:
- PostgreSQL is accepting connections
- Redis responds to PING
- Rails application responds at `/health-check`

Check health status:
```bash
docker inspect --format='{{json .State.Health.Status}}' deltabadger
```

## Backup

To backup your data:

```bash
# Stop container first for consistency
docker stop deltabadger

# Create backup
docker run --rm \
  -v deltabadger-data:/data:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/deltabadger-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restart container
docker start deltabadger
```

To restore:

```bash
docker stop deltabadger
docker run --rm \
  -v deltabadger-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/deltabadger-backup-YYYYMMDD.tar.gz -C /data"
docker start deltabadger
```

## Unraid

This container is designed for Unraid:
- Single container with all services embedded
- Health checks for container monitoring
- Simple volume mapping (`/data` contains everything)
- Environment variable configuration

## Logs

View container logs:
```bash
docker logs deltabadger
docker logs -f deltabadger  # Follow logs
```

## Troubleshooting

### Container won't start
Check logs for errors:
```bash
docker logs deltabadger
```

### Database issues
The database is automatically initialized on first run. If you need to reset:
```bash
docker stop deltabadger
docker volume rm deltabadger-data
docker start deltabadger
```

### Port already in use
Change the port mapping:
```bash
docker run -d -p 8080:3000 -v deltabadger-data:/data ghcr.io/aseimel/deltabadger-aio:latest
```

## Building Locally

```bash
docker build -f Dockerfile.aio -t deltabadger-aio:local .
docker run -d -p 3000:3000 -v deltabadger-data:/data deltabadger-aio:local
```

## Architecture

The AIO container uses [s6-overlay](https://github.com/just-containers/s6-overlay) to manage multiple services:

- **PostgreSQL 15** - Database (auto-initialized)
- **Redis 7** - Cache and job queue
- **Puma** - Rails application server
- **Sidekiq** - Background job processor

Services start in order: PostgreSQL → Redis → Rails → Sidekiq
