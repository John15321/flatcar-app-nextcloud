#!/bin/bash

# Nextcloud Update Script
set -e

COMPOSE_FILE="/opt/nextcloud/docker-compose.yml"

echo "Starting Nextcloud update at $(date)"

# Change to nextcloud directory
cd /opt/nextcloud

# Pull latest images
echo "Pulling latest Docker images..."
docker-compose pull

# Restart services with new images
echo "Restarting services..."
docker-compose down
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Run Nextcloud maintenance commands
echo "Running Nextcloud maintenance..."
docker-compose exec -T nextcloud php occ upgrade
docker-compose exec -T nextcloud php occ db:add-missing-indices
docker-compose exec -T nextcloud php occ db:convert-filecache-bigint

echo "Update completed at $(date)"
