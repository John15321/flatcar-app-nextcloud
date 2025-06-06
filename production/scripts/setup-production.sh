#!/bin/bash
# Nextcloud production setup script
set -euo pipefail

echo "Setting up Nextcloud production..."

cd /opt/nextcloud

# Setup .env
if [[ ! -f .env ]]; then
    [[ ! -f .env.example ]] && { echo "ERROR: .env.example not found" >&2; exit 1; }
    cp .env.example .env
    echo "Configure .env and run generate-secrets.sh, then run setup again"
    exit 1
fi

source .env

# Validate required variables
for var in DOMAIN ACME_EMAIL NEXTCLOUD_ADMIN_PASSWORD POSTGRES_PASSWORD REDIS_PASSWORD; do
    [[ -z "${!var:-}" ]] && { echo "ERROR: $var not set in .env" >&2; exit 1; }
done

# Setup
docker network create web 2>/dev/null || true
mkdir -p data
chown -R 33:33 data
chmod 600 .env

echo "✅ Setup complete! Run: docker-compose up -d"
echo "Access: https://${DOMAIN}"
