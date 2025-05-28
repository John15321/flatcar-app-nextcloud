#!/bin/bash

# Nextcloud Backup Script
set -e

BACKUP_DIR="/opt/nextcloud/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

echo "Starting Nextcloud backup at $(date)"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Run database backup
echo "Backing up database..."
docker-compose -f /opt/nextcloud/docker-compose.yml run --rm backup

# Cleanup old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completed at $(date)"
