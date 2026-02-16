# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git Remote Rules (ABSOLUTE — DO NOT VIOLATE)

This repository (`deltabadger-aio`) is a FORK of `deltabadger/deltabadger`. There are two remotes:

- **`fork`** (`aseimel/deltabadger-aio.git`) — THIS is our repo. Pull from here. Push to here.
- **`origin`** (`deltabadger/deltabadger.git`) — This is the UPSTREAM source repo. NEVER pull, merge, rebase, or reset to this remote.

### Rules:
1. **`git pull` / `git fetch` MUST ONLY target the `fork` remote.** NEVER `origin`.
2. **NEVER run `git reset --hard origin/...`** or any command that replaces our branch with upstream code.
3. **NEVER merge or rebase `origin/main` into our branch.** The upstream repo has a completely different history, architecture (Rails 8, SQLite, SolidQueue), and will destroy our codebase.
4. **Upstream code is ONLY integrated via manual cherry-picks** of specific bug fixes, adapted to our stack. Never wholesale branch operations.
5. **If the user says "pull from GitHub"**, they mean `fork` (aseimel/deltabadger-aio), NOT `origin`.
6. **When in doubt, ASK.** Do not guess which remote the user means.
7. **When referring to remotes in conversation, use the GitHub repo name** (`deltabadger-aio` or `deltabadger`), NOT the git remote alias (`fork` or `origin`). The user does not think in terms of git remote aliases.

**Violating these rules will destroy the codebase. There are no exceptions.**

## Container-Level Autonomy Rule (CRITICAL)

ALL changes MUST work automatically via a Docker container update. The user must NEVER need to run manual commands inside the container (`docker exec`, `rails console`, etc.). Specifically:

- **New data** (e.g., exchange records): Use raw SQL migrations, NOT seeds. Seeds only run on first startup; migrations run on every update.
- **Data migrations**: Always use raw SQL (`execute <<-SQL`), never ActiveRecord models, to avoid class-loading issues during container initialization.
- **Configuration changes**: Must be handled by migrations or init scripts, never require manual intervention.
- **The update flow is**: push to `claude/*` branch → auto-merge to main → Docker build → user pulls `:latest` → container restarts and everything works.

## Backward Compatibility Rules (MOST IMPORTANT)

### Zero-Downtime Docker Update Requirements

ALL code changes MUST preserve:

1. **Database Schema Compatibility**
   - Existing tables: `bots`, `transactions`, `daily_transaction_aggregates`, `api_keys`, etc.
   - Encrypted columns using `attr_encrypted` (key/secret/passphrase with _iv columns)
   - JSONB columns: `settings`, `transient_data`, `error_messages`
   - Foreign key constraints and indexes
   - Enum values and ordering

2. **Data Structure Integrity**
   - Bot STI types: `Bots::DcaSingleAsset`, `Bots::DcaDualAsset`, `Bots::Withdrawal`
   - Transaction status enum: `:submitted`, `:failed`, `:skipped`
   - API key types: `:trading`, `:withdrawal`
   - All existing bot settings must remain readable

3. **Infrastructure Stability**
   - PostgreSQL queries (use JSONB operators: `->`, `->>`, `@>`, `?`)
   - Sidekiq job scheduling (ActiveJob abstraction)
   - attr_encrypted for sensitive data (never Rails 8 native encryption)
   - Webpacker asset pipeline
   - s6-overlay process management

4. **API Compatibility**
   - Sidekiq::ScheduledSet, Sidekiq::Queue, Sidekiq::RetrySet
   - Transaction#cancel must continue working
   - Bot#start, Bot#stop, Bot#destroy must continue working
   - All exchange API integrations must continue working

### Upstream Integration Rules

This fork diverges from upstream deltabadger v1.6.x on infrastructure:

**NEVER Port (Incompatible)**:
- SQLite migrations (we use PostgreSQL)
- SolidQueue job system (we use Sidekiq + Redis)
- Rails 8 features (we're on Rails 6.0.6.1)
- Native ActiveRecord encryption (we use attr_encrypted)
- Removal of withdrawal bot type (we keep it)
- Removal of daily_transaction_aggregates table (we keep it)
- 2-layer exchange pattern (we keep 3-layer)
- jsbundling/esbuild configs (we use Webpacker)

**Safe to Port (After Adaptation)**:
- Bug fixes in exchange models (order parsing, error handling)
- UI improvements (SASS, CSS, JavaScript)
- Stimulus controller improvements
- Turbo stream optimizations
- New exchange implementations (adapt to 3-layer pattern)

**Requires PostgreSQL Adaptation**:
```ruby
# SQLite (upstream):
where("json_extract(settings, '$.key') = ?", value)

# PostgreSQL (our fork):
where("settings->>'key' = ?", value)
where("settings @> ?", { key: value }.to_json)
```

**Requires Sidekiq Adaptation**:
```ruby
# SolidQueue (upstream):
cancel_solid_queue_jobs(job_class: JobClass, record: self)

# Sidekiq (our fork):
Sidekiq::ScheduledSet.new.each { |job| job.delete if matches }
Sidekiq::Queue.new(queue_name).each { |job| job.delete if matches }
```

## Project Overview

Deltabadger is a self-hosted Dollar Cost Averaging (DCA) bot for cryptocurrency. It automates recurring purchases across multiple exchanges (Binance, Coinbase, Kraken, Bitstamp, Gemini, KuCoin, etc.). Built with Rails 6 + React/Redux frontend.

## Development Commands

### Setup
```bash
bin/setup                          # Install dependencies, copy config files, prepare database
bundle exec rails db:migrate       # Run pending migrations
```

### Running the App (Development)
Requires 4 terminal sessions:
```bash
bin/webpack-dev-server             # Terminal 1: Webpack dev server
rails s                            # Terminal 2: Rails server
redis-server                       # Terminal 3: Redis
bundle exec sidekiq                # Terminal 4: Background job processor
```

### Testing
```bash
bundle exec rspec                  # Run all Ruby tests
bundle exec rspec spec/path/to/file_spec.rb              # Run specific test file
bundle exec rspec spec/path/to/file_spec.rb:42           # Run specific test at line
bundle exec guard -c               # Auto-run tests on file changes

npm test                           # Run JavaScript tests (Jest)
npm run test:watch                 # Watch mode for JS tests
```

### Linting
```bash
bundle exec rubocop                # Ruby linting
bundle exec rubocop -a             # Auto-fix Ruby issues
```

### Docker (Alternative)
```bash
docker compose up                  # Start app (first run takes a few minutes)
docker compose up -d               # Run in background
docker compose down                # Stop all containers
docker compose build --no-cache    # Rebuild after code changes
```

## Architecture

### Bot System (STI Pattern)
The core domain uses Single Table Inheritance for bot types:
- `Bot` (base class) - `app/models/bot.rb`
  - `Bots::DcaSingleAsset` - Single asset DCA (e.g., buy BTC with USD)
  - `Bots::DcaDualAsset` - Dual asset DCA (e.g., 50% BTC, 50% ETH)
  - `Bots::Withdrawal` - Auto-withdraw to external wallet

Bot concerns: `Dryable`, `Typeable`, `Labelable`, `Rankable`, `Notifyable`, `DomIdable`, `ExchangeUser`

### Exchange Integration
Each exchange has three layers:
1. **Model** (`app/models/exchanges/*.rb`) - Exchange-specific configuration, supported pairs, market rules
2. **API Client** (`app/services/exchange_api/clients/*.rb`) - HTTP communication with exchange
3. **Trader** (`app/services/exchange_api/traders/{exchange}/*.rb`) - Order execution logic

Supported exchanges: Binance, Binance US, Coinbase, Kraken, Bitstamp, Gemini, KuCoin, Bitfinex, Bitso, Zonda

### Background Jobs (Sidekiq)
- `MakeTransactionWorker` - Executes scheduled DCA purchases
- `MakeWithdrawalWorker` - Processes auto-withdrawals
- `FetchResultWorker` - Fetches order execution results
- `ApiKeyValidatorWorker` - Validates API credentials

Job scheduling: `app/services/schedule_transaction.rb`, `app/services/schedule_withdrawal.rb`

### Frontend
- React/Redux for bot management UI (`app/javascript/deltabadger/`)
- Stimulus controllers (`app/javascript/controllers/`)
- Turbo for real-time updates via ActionCable

### Key Services
- `app/services/make_transaction.rb` - Core transaction execution
- `app/services/make_withdrawal.rb` - Withdrawal processing
- `app/services/fetch_order_result.rb` - Order status polling
- `app/services/api_key_validator.rb` - Exchange credential validation
- `app/services/bots_manager/` - Bot lifecycle management

### Database
PostgreSQL with encrypted fields (`attr_encrypted`) for API keys. Uses Scenic for database views (transaction aggregates).

## Environment Variables

Key variables for development (see `.env.example`):
- `SECRET_KEY_BASE`, `DEVISE_SECRET_KEY` - Rails secrets
- `APP_ENCRYPTION_KEY` - For encrypted API key storage
- `DB_*` - Database connection (production)
- `REDIS_URL` - Redis connection for Sidekiq

## macOS Development Note

If you encounter fork() crashes when loading exchanges, add to shell config:
```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```
