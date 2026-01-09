#!/bin/bash
# Generate secrets for Deltabadger AIO
# Usage: generate-secrets.sh [output_file]

OUTPUT_FILE="${1:-/data/secrets/.env.secrets}"

echo "Generating Deltabadger secrets..."

SECRET_KEY_BASE=$(openssl rand -hex 64)
DEVISE_SECRET_KEY=$(openssl rand -hex 64)
APP_ENCRYPTION_KEY=$(openssl rand -hex 16)

mkdir -p "$(dirname "$OUTPUT_FILE")"

cat > "$OUTPUT_FILE" << EOF
# Deltabadger Auto-generated Secrets
# Generated on: $(date -Iseconds)
# WARNING: Do not share or commit this file!

SECRET_KEY_BASE=${SECRET_KEY_BASE}
DEVISE_SECRET_KEY=${DEVISE_SECRET_KEY}
APP_ENCRYPTION_KEY=${APP_ENCRYPTION_KEY}
EOF

chmod 600 "$OUTPUT_FILE"

echo "Secrets saved to: $OUTPUT_FILE"
echo ""
echo "SECRET_KEY_BASE=${SECRET_KEY_BASE:0:16}..."
echo "DEVISE_SECRET_KEY=${DEVISE_SECRET_KEY:0:16}..."
echo "APP_ENCRYPTION_KEY=${APP_ENCRYPTION_KEY}"
