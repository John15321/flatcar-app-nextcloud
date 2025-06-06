#!/bin/bash
# Collabora setup for production
set -euo pipefail

OCC_CMD="/opt/bin/nextcloud-occ.sh"

# Load environment
[[ -f "/opt/nextcloud/.env" ]] && source "/opt/nextcloud/.env"
[[ -z "${DOMAIN:-}" ]] && { echo "❌ DOMAIN not set"; exit 1; }

log() { echo "$(date +%H:%M:%S) $1"; }

# Check containers
check_containers() {
    docker ps --format '{{.Names}}' | grep -q "nextcloud-app" || { echo "❌ Nextcloud not running"; return 1; }
    docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora" || { echo "❌ Collabora not running"; return 1; }
}

# Configure Collabora
configure_collabora() {
    log "🔧 Configuring Collabora..."
    
    $OCC_CMD app:install richdocuments 2>/dev/null || true
    $OCC_CMD app:enable richdocuments
    
    # Use internal HTTPS if available, otherwise HTTP
    local internal_url="http://nextcloud-collabora:9980"
    if docker exec nextcloud-app curl -k -s --connect-timeout 5 "https://nextcloud-collabora:9980/hosting/discovery" >/dev/null 2>&1; then
        internal_url="https://nextcloud-collabora:9980"
        log "✅ Using internal HTTPS"
    fi
    
    $OCC_CMD config:app:set richdocuments wopi_url --value="$internal_url"
    $OCC_CMD config:app:set richdocuments public_wopi_url --value="https://collabora.${DOMAIN}"
    $OCC_CMD config:app:set richdocuments disable_certificate_verification --value="no"
    $OCC_CMD config:app:set richdocuments edit_groups --value=""
    $OCC_CMD config:app:set richdocuments use_groups --value=""
    $OCC_CMD config:app:delete richdocuments discovery_refresh_timestamp 2>/dev/null || true
    
    echo "✅ Collabora configured with: $internal_url"
}

# Test integration
test_integration() {
    log "🧪 Testing..."
    curl -s --connect-timeout 10 "https://collabora.${DOMAIN}/hosting/discovery" >/dev/null && echo "✅ External HTTPS working" || { echo "❌ External HTTPS failed"; return 1; }
    
    local wopi_url=$($OCC_CMD config:app:get richdocuments wopi_url)
    if [[ "$wopi_url" == https* ]]; then
        docker exec nextcloud-app curl -k -s "$wopi_url/hosting/discovery" >/dev/null && echo "✅ Internal HTTPS working" || { echo "❌ Internal HTTPS failed"; return 1; }
    else
        docker exec nextcloud-app curl -s "$wopi_url/hosting/discovery" >/dev/null && echo "✅ Internal HTTP working" || { echo "❌ Internal HTTP failed"; return 1; }
    fi
}

# Show config
show_config() {
    echo "=== Configuration ==="
    echo "WOPI URL: $($OCC_CMD config:app:get richdocuments wopi_url 2>/dev/null || echo 'Not set')"
    echo "Public URL: $($OCC_CMD config:app:get richdocuments public_wopi_url 2>/dev/null || echo 'Not set')"
    echo "SSL verification: $($OCC_CMD config:app:get richdocuments disable_certificate_verification 2>/dev/null || echo 'Not set')"
}

case "${1:-configure}" in
    "configure"|"setup") check_containers && configure_collabora && test_integration && echo "✅ Configuration complete" ;;
    "test") check_containers && test_integration ;;
    "status") show_config ;;
    *) echo "Usage: $0 [configure|test|status]"; exit 1 ;;
esac
