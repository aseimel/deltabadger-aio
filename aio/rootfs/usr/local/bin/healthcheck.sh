#!/bin/bash
# Health check for AIO container - all services must be healthy

set -e

# Check PostgreSQL
if ! pg_isready -h localhost -U "${DB_USER:-deltabadger}" -d "${DB_NAME:-deltabadger_production}" -q; then
    echo "PostgreSQL is not ready"
    exit 1
fi

# Check Redis
if ! redis-cli -h localhost ping 2>/dev/null | grep -q PONG; then
    echo "Redis is not ready"
    exit 1
fi

# Check Rails application
if ! curl -sf http://localhost:3000/health-check > /dev/null; then
    echo "Rails application is not ready"
    exit 1
fi

# All checks passed
exit 0
