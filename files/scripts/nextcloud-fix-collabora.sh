#!/bin/bash

# Collabora Quick Fix Script
# Automated fixes for common Collabora Online issues

set -euo pipefail

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

NEXTCLOUD_DIR="/opt/nextcloud"
OCC_CMD="/opt/bin/nextcloud-occ.sh"

# Fix 1: Restart Collabora container
fix_restart_collabora() {
    log "Fix 1: Restarting Collabora container..."
    
    if docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora"; then
        docker restart nextcloud-collabora
        log "Waiting 30 seconds for Collabora to fully start..."
        sleep 30
        
        if curl -s --connect-timeout 10 "http://localhost:9980/hosting/discovery" > /dev/null; then
            log_success "Collabora restarted successfully"
            return 0
        else
            log_warning "Collabora still not responding after restart"
            return 1
        fi
    else
        log_error "Collabora container not found"
        return 1
    fi
}

# Fix 2: Recreate all containers with fresh images
fix_recreate_containers() {
    log "Fix 2: Recreating containers with fresh images..."
    
    cd "$NEXTCLOUD_DIR"
    
    log "Stopping containers..."
    docker-compose down
    
    log "Pulling latest images..."
    docker-compose pull
    
    log "Starting containers..."
    docker-compose up -d
    
    log "Waiting 60 seconds for services to start..."
    sleep 60
    
    # Test if services are up
    local retries=0
    while [ $retries -lt 10 ]; do
        if docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora" && \
           docker ps --format '{{.Names}}' | grep -q "nextcloud-app" && \
           curl -s --connect-timeout 5 "http://localhost:8080" > /dev/null; then
            log_success "Containers recreated successfully"
            return 0
        fi
        
        retries=$((retries + 1))
        log "Waiting for services... (attempt $retries/10)"
        sleep 10
    done
    
    log_error "Containers failed to start properly"
    return 1
}

# Fix 3: Reset and reconfigure Collabora integration
fix_reconfigure_collabora() {
    log "Fix 3: Resetting and reconfiguring Collabora integration..."
    
    cd "$NEXTCLOUD_DIR"
    
    # Wait for Nextcloud to be ready
    local retries=0
    while [ $retries -lt 20 ]; do
        if $OCC_CMD status >/dev/null 2>&1; then
            break
        fi
        retries=$((retries + 1))
        log "Waiting for Nextcloud... (attempt $retries/20)"
        sleep 5
    done
    
    if [ $retries -eq 20 ]; then
        log_error "Nextcloud not ready after waiting"
        return 1
    fi
    
    # Disable and re-enable richdocuments
    log "Resetting richdocuments app..."
    $OCC_CMD app:disable richdocuments 2>/dev/null || true
    sleep 2
    $OCC_CMD app:enable richdocuments 2>/dev/null || true
    
    # Clear all existing Collabora config
    log "Clearing existing configuration..."
    $OCC_CMD config:app:delete richdocuments wopi_url 2>/dev/null || true
    $OCC_CMD config:app:delete richdocuments public_wopi_url 2>/dev/null || true
    $OCC_CMD config:app:delete richdocuments wopi_callback_url 2>/dev/null || true
    $OCC_CMD config:app:delete richdocuments wopi_allowlist 2>/dev/null || true
    $OCC_CMD config:app:delete richdocuments discovery_refresh_timestamp 2>/dev/null || true
    
    # Reconfigure with correct settings
    log "Applying new configuration with HTTP URLs and allowlist..."
    /opt/bin/nextcloud-collabora-setup.sh configure
    
    log_success "Collabora integration reset and reconfigured"
}

# Fix 4: Use specific Collabora version (if latest is problematic)
fix_use_stable_version() {
    log "Fix 4: Switching to stable Collabora version..."
    
    cd "$NEXTCLOUD_DIR"
    
    # Backup current docker-compose.yml
    cp docker-compose.yml docker-compose.yml.backup
    
    # Replace collabora image with stable version
    sed -i 's/collabora\/code:latest/collabora\/code:23.05.9.1.1/' docker-compose.yml
    
    log "Recreating with stable version..."
    docker-compose down
    docker-compose up -d
    
    log "Waiting 60 seconds for stable version to start..."
    sleep 60
    
    if curl -s --connect-timeout 10 "http://localhost:9980/hosting/discovery" > /dev/null; then
        log_success "Stable Collabora version working"
        return 0
    else
        log_warning "Stable version also having issues, reverting..."
        mv docker-compose.yml.backup docker-compose.yml
        docker-compose down
        docker-compose up -d
        return 1
    fi
}

# Main function with progressive fixes
main() {
    local fix_option="${1:-auto}"
    
    case "$fix_option" in
        "1"|"restart")
            fix_restart_collabora
            ;;
        "2"|"recreate")
            fix_recreate_containers && fix_reconfigure_collabora
            ;;
        "3"|"reconfigure")
            fix_reconfigure_collabora
            ;;
        "4"|"stable")
            fix_use_stable_version && fix_reconfigure_collabora
            ;;
        "auto"|*)
            log "🔧 Starting automated Collabora troubleshooting..."
            echo ""
            
            # Try fixes in order of increasing impact
            if fix_restart_collabora; then
                log_success "🎉 Fixed with simple restart!"
                exit 0
            fi
            
            log "Restart didn't work, trying reconfiguration..."
            if fix_reconfigure_collabora; then
                log_success "🎉 Fixed with reconfiguration!"
                exit 0
            fi
            
            log "Reconfiguration didn't work, recreating containers..."
            if fix_recreate_containers && fix_reconfigure_collabora; then
                log_success "🎉 Fixed with container recreation!"
                exit 0
            fi
            
            log "Standard fixes didn't work, trying stable version..."
            if fix_use_stable_version && fix_reconfigure_collabora; then
                log_success "🎉 Fixed with stable Collabora version!"
                exit 0
            fi
            
            log_error "😞 All automated fixes failed"
            echo ""
            echo "Manual troubleshooting required:"
            echo "1. Run: nextcloud-debug-collabora.sh"
            echo "2. Check for HTTPS vs HTTP URL issues"
            echo "3. Verify WOPI allowlist is configured"
            echo "4. Check logs: docker logs nextcloud-collabora"
            echo "5. Check Nextcloud logs: nextcloud-logs.sh"
            echo "6. Consider using docker-compose.collabora.yml separately"
            echo ""
            echo "Common issues and manual fixes:"
            echo "- If seeing HTTPS connection errors, ensure public_wopi_url uses HTTP:"
            echo "  nextcloud-occ.sh config:app:set richdocuments public_wopi_url --value='http://localhost:9980'"
            echo "- If seeing WOPI allowlist warning:"
            echo "  nextcloud-occ.sh config:app:set richdocuments wopi_allowlist --value='127.0.0.1,::1,localhost,nextcloud-app'"
            exit 1
            ;;
    esac
    
    # After any manual fix, test the result
    echo ""
    log "Testing fix result..."
    if curl -s --connect-timeout 10 "http://localhost:9980/hosting/discovery" > /dev/null; then
        log_success "🎉 Collabora is now working!"
        echo ""
        echo "Test it by:"
        echo "1. Go to http://localhost:8080"
        echo "2. Create a new document"
        echo "3. Try editing it online"
    else
        log_error "Fix didn't resolve the issue"
        echo "Run 'nextcloud-debug-collabora.sh' for detailed diagnostics"
    fi
}

if [ $# -eq 0 ]; then
    echo "Collabora Quick Fix Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  auto       Try all fixes automatically (default)"
    echo "  1|restart  Just restart Collabora container"
    echo "  2|recreate Recreate all containers with fresh images"
    echo "  3|reconfigure Reset and reconfigure Collabora integration"
    echo "  4|stable   Use stable Collabora version instead of latest"
    echo ""
    echo "Examples:"
    echo "  $0           # Try all fixes automatically"
    echo "  $0 restart   # Just restart Collabora"
    echo "  $0 recreate  # Nuclear option - recreate everything"
fi

main "$@"
