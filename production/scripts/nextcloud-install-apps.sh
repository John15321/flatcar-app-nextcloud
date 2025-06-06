#!/bin/bash
# Production Nextcloud Apps Installation
set -euo pipefail

OCC_CMD="/opt/bin/nextcloud-occ.sh"

log() { echo "[$(date +%H:%M:%S)] $1"; }

# Wait for Nextcloud
wait_for_nextcloud() {
    log "Waiting for Nextcloud..."
    for i in {1..30}; do
        $OCC_CMD status >/dev/null 2>&1 && { log "Nextcloud ready!"; return 0; }
        sleep 10
    done
    echo "ERROR: Nextcloud not responding" >&2; exit 1
}

# Install essential apps
install_apps() {
    local apps=(
        "richdocuments" "files_external" "user_ldap" "calendar" 
        "contacts" "mail" "notes" "tasks" "deck" "admin_audit"
    )
    
    log "Installing apps..."
    for app in "${apps[@]}"; do
        if $OCC_CMD app:install "$app" 2>/dev/null; then
            $OCC_CMD app:enable "$app" 2>/dev/null
            log "✓ $app"
        else
            log "⚠ Skipped: $app"
        fi
    done
}

# Configure Collabora
configure_collabora() {
    [[ -f "/opt/nextcloud/.env" ]] && source "/opt/nextcloud/.env"
    [[ -z "${DOMAIN:-}" ]] && { echo "ERROR: DOMAIN not set" >&2; exit 1; }
    
    if docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora"; then
        log "Configuring Collabora..."
        $OCC_CMD config:app:set richdocuments wopi_url --value="http://nextcloud-collabora:9980"
        $OCC_CMD config:app:set richdocuments public_wopi_url --value="https://collabora.${DOMAIN}"
        $OCC_CMD config:app:set richdocuments disable_certificate_verification --value="no"
        log "✓ Collabora configured"
    fi
}

main() {
    wait_for_nextcloud
    install_apps
    configure_collabora
    log "✅ Apps installation complete!"
}

main "$@"
