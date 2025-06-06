#!/bin/bash
# Deploy Nextcloud to production
set -euo pipefail

# Check prerequisites
[[ $EUID -ne 0 ]] && { echo "Must run as root" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker not running" >&2; exit 1; }
[[ ! -d /opt/nextcloud ]] && { echo "Nextcloud directory not found" >&2; exit 1; }

echo "🚀 Deploying Nextcloud..."
cd /opt/nextcloud

/opt/bin/setup-production.sh
docker-compose up -d

echo "✅ Deployment complete!"
docker-compose ps
