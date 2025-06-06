#!/bin/bash
# Production deployment helper
set -euo pipefail

log() { echo "[INFO] $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

# Check prerequisites
[[ $EUID -ne 0 ]] && error "Must run as root (use sudo)"
docker info >/dev/null 2>&1 || error "Docker not running"
[[ ! -d /opt/nextcloud ]] && error "Nextcloud directory not found"
[[ ! -f /opt/nextcloud/.env ]] && error ".env file missing - copy from .env.example"

echo "🚀 Nextcloud Production Deployment"
echo "=================================="
echo "1. Standard (external HTTPS, internal HTTP)"
echo "2. Internal HTTPS (external + internal HTTPS)"
echo "3. Exit"

read -p "Choose option (1-3): " choice

cd /opt/nextcloud

case $choice in
    1)
        log "Deploying standard production..."
        /opt/bin/setup-production.sh
        docker-compose up -d
        ;;
    2)
        log "Deploying with internal HTTPS..."
        /opt/bin/setup-production.sh --internal-https
        docker-compose -f docker-compose.internal-https.yml up -d
        ;;
    3)
        exit 0
        ;;
    *)
        error "Invalid choice"
        ;;
esac

log "✅ Deployment complete!"
source .env
log "Access: https://${DOMAIN:-$PUBLIC_IP}"
