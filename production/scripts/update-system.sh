#!/bin/bash
# System security update script
set -euo pipefail

log() { echo "[UPDATE] $1"; }

main() {
    log "Starting system updates..."
    
    # Check Flatcar updates
    log "Checking Flatcar updates..."
    update_engine_client -status 2>/dev/null || log "Update engine check failed"
    
    # Update containers
    if docker ps --filter name=nextcloud-watchtower --format "{{.Names}}" | grep -q watchtower; then
        log "Watchtower running - updates automated"
    else
        log "Updating containers manually..."
        cd /opt/nextcloud 2>/dev/null || { log "Nextcloud dir not found"; exit 1; }
        docker-compose pull
        docker-compose up -d
        docker image prune -f
    fi
    
    # Security checks
    log "Security checks..."
    if journalctl --since "24 hours ago" | grep -i "failed\|error\|security" | head -5 | grep -q .; then
        log "⚠ Security events found in logs"
    else
        log "✓ No security events"
    fi
    
    unhealthy=$(docker ps --filter health=unhealthy --format "{{.Names}}" | wc -l)
    if [[ $unhealthy -gt 0 ]]; then
        log "⚠ $unhealthy unhealthy containers"
        docker ps --filter health=unhealthy --format "table {{.Names}}\t{{.Status}}"
    else
        log "✓ All containers healthy"
    fi
    
    log "✅ System update complete"
}

main "$@"
