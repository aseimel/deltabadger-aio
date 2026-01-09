# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
