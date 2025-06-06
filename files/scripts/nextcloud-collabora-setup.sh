#!/bin/bash

# Collabora Configuration and Testing Script
# Configures Collabora Online integration with Nextcloud and runs connectivity tests

set -euo pipefail

# Configuration
NEXTCLOUD_DIR="/opt/nextcloud"
OCC_CMD="/opt/bin/nextcloud-occ.sh"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ✅ $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ⚠️  $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ❌ $1"
}

# Check if containers are running
check_containers() {
    log "Checking container status..."
    
    if ! docker ps --format '{{.Names}}' | grep -q "nextcloud-app"; then
        log_error "Nextcloud container is not running"
        return 1
    fi
    log_success "Nextcloud container is running"
    
    if ! docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora"; then
        log_error "Collabora container is not running"
        return 1
    fi
    log_success "Collabora container is running"
    
    return 0
}

# Test Collabora service
test_collabora_service() {
    log "Testing Collabora service..."
    
    # Test discovery endpoint
    if curl -s "http://localhost:9980/hosting/discovery" > /dev/null; then
        log_success "Collabora discovery endpoint is accessible"
    else
        log_error "Collabora discovery endpoint is not accessible"
        return 1
    fi
    
    # Test capabilities
    if curl -s "http://localhost:9980/hosting/capabilities" | grep -q "HasEditSupport"; then
        log_success "Collabora capabilities endpoint is working"
    else
        log_warning "Collabora capabilities endpoint may have issues"
    fi
    
    return 0
}

# Configure Collabora in Nextcloud
configure_collabora() {
    log "Configuring Collabora integration in Nextcloud..."
    
    cd "$NEXTCLOUD_DIR"
    
    # Ensure richdocuments app is installed and enabled
    if ! $OCC_CMD app:list | grep -q "richdocuments"; then
        log "Installing richdocuments app..."
        $OCC_CMD app:install richdocuments || {
            log_error "Failed to install richdocuments app"
            return 1
        }
    fi
    
    $OCC_CMD app:enable richdocuments || {
        log_error "Failed to enable richdocuments app"
        return 1
    }
    log_success "richdocuments app is enabled"
    
    # Configure WOPI settings
    log "Setting up WOPI configuration..."
    
    # Clear any existing configuration first to avoid conflicts
    $OCC_CMD config:app:delete richdocuments wopi_url 2>/dev/null || true
    $OCC_CMD config:app:delete richdocuments public_wopi_url 2>/dev/null || true
    $OCC_CMD config:app:delete richdocuments wopi_callback_url 2>/dev/null || true
    $OCC_CMD config:app:delete richdocuments wopi_allowlist 2>/dev/null || true
    
    # Set the Collabora server URL (internal container communication)
    $OCC_CMD config:app:set richdocuments wopi_url --value="http://nextcloud-collabora:9980" || {
        log_error "Failed to set WOPI URL"
        return 1
    }
    
    # Set the public URL for browser access (NO HTTPS!)
    $OCC_CMD config:app:set richdocuments public_wopi_url --value="http://localhost:9980" || {
        log_error "Failed to set public WOPI URL"
        return 1
    }
    
    # Set WOPI allowlist to prevent security warning
    $OCC_CMD config:app:set richdocuments wopi_allowlist --value="127.0.0.1,::1,localhost,nextcloud-app" || {
        log_warning "Failed to set WOPI allowlist"
    }
    
    # Disable certificate verification for development
    $OCC_CMD config:app:set richdocuments disable_certificate_verification --value="yes"
    
    # Set callback URL (how Collabora reaches back to Nextcloud)
    $OCC_CMD config:app:set richdocuments wopi_callback_url --value="http://nextcloud-app:80"
    
    # Enable for all users
    $OCC_CMD config:app:set richdocuments edit_groups --value=""
    $OCC_CMD config:app:set richdocuments use_groups --value=""
    
    # Additional settings for better compatibility
    $OCC_CMD config:app:set richdocuments timeout --value="30"
    $OCC_CMD config:app:set richdocuments watermark_text --value=""
    
    # Force refresh of discovery info
    $OCC_CMD config:app:delete richdocuments discovery_refresh_timestamp 2>/dev/null || true
    
    log_success "Collabora WOPI configuration completed"
}

# Test Nextcloud-Collabora integration
test_integration() {
    log "Testing Nextcloud-Collabora integration..."
    
    cd "$NEXTCLOUD_DIR"
    
    # Check if richdocuments is properly configured
    local wopi_url
    wopi_url=$($OCC_CMD config:app:get richdocuments wopi_url 2>/dev/null || echo "")
    
    if [ -z "$wopi_url" ]; then
        log_error "WOPI URL is not configured"
        return 1
    fi
    log_success "WOPI URL is configured: $wopi_url"
    
    # Test internal connectivity
    log "Testing internal container connectivity..."
    if docker exec nextcloud-app curl -s "http://nextcloud-collabora:9980/hosting/discovery" > /dev/null; then
        log_success "Internal container connectivity is working"
    else
        log_error "Internal container connectivity failed"
        return 1
    fi
    
    return 0
}

# Show configuration summary
show_config() {
    log "Current Collabora configuration:"
    cd "$NEXTCLOUD_DIR"
    
    echo "  WOPI URL: $($OCC_CMD config:app:get richdocuments wopi_url 2>/dev/null || echo 'Not set')"
    echo "  Public WOPI URL: $($OCC_CMD config:app:get richdocuments public_wopi_url 2>/dev/null || echo 'Not set')"
    echo "  Callback URL: $($OCC_CMD config:app:get richdocuments wopi_callback_url 2>/dev/null || echo 'Not set')"
    echo "  WOPI Allowlist: $($OCC_CMD config:app:get richdocuments wopi_allowlist 2>/dev/null || echo 'Not set')"
    echo "  SSL verification: $($OCC_CMD config:app:get richdocuments disable_certificate_verification 2>/dev/null || echo 'Not set')"
    echo ""
    echo "Access URLs:"
    echo "  Nextcloud: http://localhost:8080"
    echo "  Collabora: http://localhost:9980"
    echo "  Discovery: http://localhost:9980/hosting/discovery"
    echo "  Admin Panel: http://localhost:9980 (admin/admin123)"
}

# Troubleshooting function
troubleshoot() {
    log "Running comprehensive Collabora troubleshooting..."
    
    echo "=== Container Status ==="
    docker ps --filter name=nextcloud --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo "=== Collabora Logs (last 30 lines) ==="
    docker logs --tail 30 nextcloud-collabora 2>/dev/null || echo "Could not retrieve Collabora logs"
    echo ""
    
    echo "=== Nextcloud Logs (richdocuments related) ==="
    docker exec nextcloud-app grep -i "richdocuments\|collabora\|wopi" /var/www/html/data/nextcloud.log 2>/dev/null | tail -10 || echo "No richdocuments logs found"
    echo ""
    
    echo "=== Network Connectivity Tests ==="
    # Test container-to-container connectivity
    if docker exec nextcloud-app ping -c 1 nextcloud-collabora > /dev/null 2>&1; then
        echo "✅ Nextcloud can reach Collabora container"
    else
        echo "❌ Nextcloud cannot reach Collabora container"
    fi
    
    # Test port connectivity
    if docker exec nextcloud-app nc -z nextcloud-collabora 9980 2>/dev/null; then
        echo "✅ Collabora port 9980 is accessible from Nextcloud"
    else
        echo "❌ Collabora port 9980 is not accessible from Nextcloud"
    fi
    
    # Test reverse connectivity
    if docker exec nextcloud-collabora nc -z nextcloud-app 80 2>/dev/null; then
        echo "✅ Nextcloud port 80 is accessible from Collabora"
    else
        echo "❌ Nextcloud port 80 is not accessible from Collabora"
    fi
    
    echo ""
    echo "=== Collabora Service Endpoints ==="
    # Test discovery endpoint
    echo -n "Discovery endpoint: "
    if curl -s --connect-timeout 5 "http://localhost:9980/hosting/discovery" | head -1 | grep -q "xml"; then
        echo "✅ Working"
    else
        echo "❌ Not working"
    fi
    
    # Test capabilities endpoint
    echo -n "Capabilities endpoint: "
    if curl -s --connect-timeout 5 "http://localhost:9980/hosting/capabilities" | grep -q "HasEditSupport"; then
        echo "✅ Working"
    else
        echo "❌ Not working"
    fi
    
    echo ""
    echo "=== WOPI Configuration Check ==="
    cd "$NEXTCLOUD_DIR"
    echo "Current richdocuments configuration:"
    $OCC_CMD config:app:get richdocuments wopi_url 2>/dev/null && echo " ✅ WOPI URL set" || echo " ❌ WOPI URL not set"
    $OCC_CMD config:app:get richdocuments public_wopi_url 2>/dev/null && echo " ✅ Public WOPI URL set" || echo " ❌ Public WOPI URL not set"
    $OCC_CMD config:app:get richdocuments wopi_callback_url 2>/dev/null && echo " ✅ Callback URL set" || echo " ❌ Callback URL not set"
    
    echo ""
    echo "=== Suggested Fix Commands ==="
    echo "If issues persist, try these commands:"
    echo "1. Recreate containers:"
    echo "   cd /opt/nextcloud && docker-compose down && docker-compose up -d"
    echo ""
    echo "2. Reconfigure Collabora:"
    echo "   /opt/bin/nextcloud-collabora-setup.sh configure"
    echo ""
    echo "3. Check Nextcloud logs:"
    echo "   docker exec nextcloud-app tail -f /var/www/html/data/nextcloud.log"
    echo ""
    echo "4. Test WOPI discovery manually:"
    echo "   curl -v http://localhost:9980/hosting/discovery"
}

# Main function
main() {
    case "${1:-configure}" in
        "configure")
            log "🔧 Configuring Collabora Online integration..."
            
            if ! check_containers; then
                log_error "Required containers are not running"
                exit 1
            fi
            
            if ! test_collabora_service; then
                log_error "Collabora service is not working properly"
                exit 1
            fi
            
            if ! configure_collabora; then
                log_error "Failed to configure Collabora"
                exit 1
            fi
            
            if ! test_integration; then
                log_error "Integration test failed"
                exit 1
            fi
            
            show_config
            log_success "🎉 Collabora configuration completed successfully!"
            ;;
            
        "test")
            log "🧪 Testing Collabora integration..."
            check_containers && test_collabora_service && test_integration
            ;;
            
        "status")
            log "📊 Collabora status and configuration..."
            show_config
            ;;
            
        "troubleshoot")
            log "🔍 Troubleshooting Collabora issues..."
            troubleshoot
            ;;
            
        "help"|*)
            echo "Collabora Configuration Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  configure      Configure Collabora integration (default)"
            echo "  test          Test Collabora connectivity and integration"
            echo "  status        Show current configuration"
            echo "  troubleshoot  Run troubleshooting diagnostics"
            echo "  help          Show this help message"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
