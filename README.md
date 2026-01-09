# Deltabadger AIO (All-in-One)

> **This is a fork and repackage of [Deltabadger](https://github.com/deltabadger/deltabadger).**
>
> All credit for the original application goes to the Deltabadger team. This repository simply provides an All-in-One Docker container with embedded PostgreSQL and Redis for easier deployment, particularly on systems like Unraid.

---

Auto-DCA for crypto. Automate your Dollar Cost Averaging strategy across multiple exchanges. As a service, [Deltabadger](https://deltabadger.com) helped users invest over $72 million into Bitcoin and other digital assets. Now it's free and open-source.

![dashboard](https://github.com/user-attachments/assets/c5855ad4-78e4-4093-8007-539a919cd139)

![Frame 306](https://github.com/user-attachments/assets/adbdb6f3-548e-46ea-bd6f-6c9474f60c19)

## What's Different in This Fork?

This fork provides a single **All-in-One (AIO) container** that bundles:
- PostgreSQL 15
- Redis 7
- Rails (Puma) web server
- Sidekiq background worker
- s6-overlay for process supervision

**No external database or Redis required** - just run the container and go.

## Quick Start (AIO Container)

```bash
docker run -d \
  --name deltabadger \
  -p 3000:3000 \
  -v /path/to/data:/data \
  -e APP_ROOT_URL=http://your-server-ip:3000 \
  ghcr.io/aseimel/deltabadger-aio:latest
```

Access the app at `http://localhost:3000` and create your account.

### Persistent Data

Mount a volume to `/data` to persist:
- PostgreSQL database
- Redis data
- Application secrets (auto-generated on first run)

## Unraid Installation

An Unraid template is available for easy installation:

1. In Unraid, go to **Docker** tab
2. Click **Add Container**
3. Toggle to **XML View** (top right)
4. Paste the contents from [unraid/deltabadger-aio.xml](unraid/deltabadger-aio.xml)
5. Click **Apply**

Or manually configure:
- **Repository:** `ghcr.io/aseimel/deltabadger-aio:latest`
- **Port:** `3000`
- **Path:** `/mnt/user/docker/appdata/deltabadger-aio` -> `/data`
- **Variable:** `APP_ROOT_URL` = `http://YOUR_UNRAID_IP:3000`

## Docker Compose (AIO)

```yaml
services:
  deltabadger:
    image: ghcr.io/aseimel/deltabadger-aio:latest
    container_name: deltabadger
    ports:
      - "3000:3000"
    volumes:
      - deltabadger-data:/data
    environment:
      - APP_ROOT_URL=http://localhost:3000
      - TZ=America/New_York
    restart: unless-stopped

volumes:
  deltabadger-data:
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ROOT_URL` | `http://localhost:3000` | Full URL where the app is accessible |
| `TZ` | `UTC` | Timezone |
| `SMTP_ADDRESS` | - | SMTP server for email notifications |
| `SMTP_PORT` | `25` | SMTP port |
| `SMTP_USER_NAME` | - | SMTP username |
| `SMTP_PASSWORD` | - | SMTP password |
| `SMTP_DOMAIN` | `localhost` | SMTP HELO domain |
| `NOTIFICATIONS_SENDER` | `noreply@localhost` | From address for emails |
| `COINGECKO_API_KEY` | - | CoinGecko API key (optional) |
| `ORDERS_FREQUENCY_LIMIT` | `60` | Minimum seconds between orders |

Secrets (`SECRET_KEY_BASE`, `DEVISE_SECRET_KEY`, `APP_ENCRYPTION_KEY`) are auto-generated on first run and stored in `/data/secrets/`.

---

## Original Docker Compose Setup

If you prefer the original multi-container setup with separate PostgreSQL and Redis, see the [upstream repository](https://github.com/deltabadger/deltabadger).

### Prerequisites

Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) for your operating system.

### 1. Create environment file

```bash
cp .env.docker.example .env.docker
```

### 2. Start the app

```bash
docker compose up
```

First run takes a few minutes. Access the app at `http://localhost:3000`.

---

## Development Setup

### Requirements

- Ruby 3.2.3
- Node.js 18.19.1
- PostgreSQL
- Redis

Use [asdf](https://asdf-vm.com) or your preferred version manager.

### 1. Install dependencies

```bash
bin/setup
```

### 2. Database

```bash
bundle exec rails db:migrate
```

### 3. Start services

Terminal 1 — Webpack:
```bash
bin/webpack-dev-server
```

Terminal 2 — Rails:
```bash
rails s
```

Terminal 3 — Redis:
```bash
redis-server
```

Terminal 4 — Sidekiq:
```bash
bundle exec sidekiq
```

### Running tests

```bash
bundle exec rspec
```

---

## Troubleshooting

### Container won't start

Check logs:
```bash
docker logs deltabadger
```

### Port already in use

Change the port mapping: `-p 3001:3000`

### macOS: fork() crash (development)

Add to your shell config:
```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

---

## Credits

- **Original Project:** [Deltabadger](https://github.com/deltabadger/deltabadger) by the Deltabadger team
- **AIO Repackage:** This fork

## License

[AGPL-3.0](LICENSE)
