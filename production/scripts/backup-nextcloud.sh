#!/bin/bash
# Nextcloud production backup script
set -euo pipefail

BACKUP_DIR="/opt/backups"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

log() { echo "[BACKUP] $1"; }

cd /opt/nextcloud
[[ -f .env ]] && source .env || { echo "ERROR: .env not found" >&2; exit 1; }

# Create backup directory
backup_path="$BACKUP_DIR/nextcloud_backup_$TIMESTAMP"
mkdir -p "$backup_path"

log "Starting backup to $backup_path..."

# Enable maintenance mode
log "Enabling maintenance mode..."
docker-compose exec -u www-data nextcloud php occ maintenance:mode --on 2>/dev/null || true

# Backup database
log "Backing up database..."
docker-compose exec -T db pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$backup_path/database.sql.gz"

# Backup files
log "Backing up data..."
tar -czf "$backup_path/nextcloud_data.tar.gz" -C /opt/nextcloud data config apps
cp .env "$backup_path/env_backup"

# Disable maintenance mode
log "Disabling maintenance mode..."
docker-compose exec -u www-data nextcloud php occ maintenance:mode --off 2>/dev/null || true

# Backup info
cat > "$backup_path/backup_info.txt" << EOF
Nextcloud Backup - $(date)
Database: $POSTGRES_DB
Domain: ${DOMAIN:-N/A}
Files: database.sql.gz, nextcloud_data.tar.gz, env_backup
EOF

# Cleanup old backups
log "Cleaning old backups (>$RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "nextcloud_backup_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true

backup_size=$(du -sh "$backup_path" | cut -f1)
log "✅ Backup complete! Size: $backup_size"
