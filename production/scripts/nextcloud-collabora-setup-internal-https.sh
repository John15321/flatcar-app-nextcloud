#!/bin/bash

# Collabora setup for production with internal HTTPS support
set -euo pipefail

OCC_CMD="/opt/bin/nextcloud-occ.sh"

# Load environment variables
ENV_FILE="/opt/nextcloud/.env"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
else
    echo "❌ Environment file not found: $ENV_FILE"
    exit 1
fi

[[ -z "${DOMAIN:-}" ]] && { echo "❌ DOMAIN not set in $ENV_FILE"; exit 1; }

# URLs
NEXTCLOUD_URL="https://${DOMAIN}"
COLLABORA_URL="https://collabora.${DOMAIN}"

log() { echo "$(date +'%H:%M:%S') $1"; }

# Check containers are running
check_containers() {
    docker ps --format '{{.Names}}' | grep -q "nextcloud-app" || { echo "❌ Nextcloud not running"; return 1; }
    docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora" || { echo "❌ Collabora not running"; return 1; }
    return 0
}

# Configure Collabora integration
configure_collabora() {
    log "🔧 Configuring Collabora integration..."
    
    # Install and enable richdocuments app
    $OCC_CMD app:install richdocuments 2>/dev/null || true
    $OCC_CMD app:enable richdocuments
    
    # Detect internal HTTPS availability
    local internal_url="http://nextcloud-collabora:9980"
    if docker exec nextcloud-app curl -k -s --connect-timeout 5 "https://nextcloud-collabora:9980/hosting/discovery" >/dev/null 2>&1; then
        internal_url="https://nextcloud-collabora:9980"
        log "✅ Using internal HTTPS"
    else
        log "⚠️ Using internal HTTP"
    fi
    
    # Configure WOPI settings
    $OCC_CMD config:app:set richdocuments wopi_url --value="$internal_url"
    $OCC_CMD config:app:set richdocuments public_wopi_url --value="$COLLABORA_URL"
    
    # Set certificate verification based on scheme
    if [[ "$internal_url" == https* ]]; then
        $OCC_CMD config:app:set richdocuments disable_certificate_verification --value="no"
    else
        $OCC_CMD config:app:set richdocuments disable_certificate_verification --value="yes"
    fi
    
    # Basic settings
    $OCC_CMD config:app:set richdocuments edit_groups --value=""
    $OCC_CMD config:app:set richdocuments use_groups --value=""
    $OCC_CMD config:app:delete richdocuments discovery_refresh_timestamp 2>/dev/null || true
    
    echo "✅ Collabora configured with: $internal_url"
}

# Test integration
test_integration() {
    log "🧪 Testing integration..."
    
    # Test external access
    if curl -s --connect-timeout 10 "${COLLABORA_URL}/hosting/discovery" >/dev/null; then
        echo "✅ External HTTPS access working"
    else
        echo "❌ External HTTPS access failed"
        return 1
    fi
    
    # Test internal access
    local wopi_url=$($OCC_CMD config:app:get richdocuments wopi_url)
    if [[ "$wopi_url" == https* ]]; then
        if docker exec nextcloud-app curl -k -s "$wopi_url/hosting/discovery" >/dev/null; then
            echo "✅ Internal HTTPS access working"
        else
            echo "❌ Internal HTTPS access failed"
            return 1
        fi
    else
        if docker exec nextcloud-app curl -s "$wopi_url/hosting/discovery" >/dev/null; then
            echo "✅ Internal HTTP access working"
        else
            echo "❌ Internal HTTP access failed"
            return 1
        fi
    fi
    
    return 0
}

# Show current configuration
show_config() {
    echo "=== Configuration ==="
    echo "WOPI URL: $($OCC_CMD config:app:get richdocuments wopi_url 2>/dev/null || echo 'Not set')"
    echo "Public WOPI URL: $($OCC_CMD config:app:get richdocuments public_wopi_url 2>/dev/null || echo 'Not set')"
    echo "SSL verification: $($OCC_CMD config:app:get richdocuments disable_certificate_verification 2>/dev/null || echo 'Not set')"
    echo ""
    echo "URLs:"
    echo "  Nextcloud: $NEXTCLOUD_URL"
    echo "  Collabora: $COLLABORA_URL"
}

# Main function
case "${1:-configure}" in
    "configure"|"setup")
        log "🚀 Configuring Collabora with internal HTTPS support..."
        check_containers && configure_collabora && test_integration
        echo "✅ Configuration complete"
        ;;
    "test")
        log "🧪 Testing Collabora integration..."
        check_containers && test_integration
        ;;
    "status")
        show_config
        ;;
    *)
        echo "Usage: $0 [configure|test|status]"
        echo "  configure - Configure Collabora integration (default)"
        echo "  test      - Test Collabora connectivity"
        echo "  status    - Show current configuration"
        exit 1
        ;;
esac
