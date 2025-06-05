#!/bin/bash

# Collabora Debug Script
# Comprehensive debugging for Collabora Online integration issues

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

# Configuration
NEXTCLOUD_DIR="/opt/nextcloud"
OCC_CMD="/opt/bin/nextcloud-occ.sh"

# Step 1: Check Docker setup
check_docker_setup() {
    log "=== CHECKING DOCKER SETUP ==="
    
    echo "Docker containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" --filter name=nextcloud
    echo ""
    
    # Check if containers are running
    if docker ps --format '{{.Names}}' | grep -q "nextcloud-app"; then
        log_success "Nextcloud container is running"
    else
        log_error "Nextcloud container is not running!"
        return 1
    fi
    
    if docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora"; then
        log_success "Collabora container is running"
    else
        log_error "Collabora container is not running!"
        return 1
    fi
    
    # Check network
    echo "Docker network:"
    docker network ls | grep nextcloud || log_warning "No nextcloud network found"
    echo ""
    
    return 0
}

# Step 2: Test network connectivity
test_network_connectivity() {
    log "=== TESTING NETWORK CONNECTIVITY ==="
    
    # Test container-to-container communication
    echo "Testing Nextcloud -> Collabora connectivity:"
    if docker exec nextcloud-app ping -c 2 nextcloud-collabora > /dev/null 2>&1; then
        log_success "Ping test passed"
    else
        log_error "Ping test failed"
    fi
    
    if docker exec nextcloud-app nc -z nextcloud-collabora 9980 2>/dev/null; then
        log_success "Port 9980 is accessible"
    else
        log_error "Port 9980 is not accessible"
    fi
    
    echo ""
    echo "Testing Collabora -> Nextcloud connectivity:"
    if docker exec nextcloud-collabora ping -c 2 nextcloud-app > /dev/null 2>&1; then
        log_success "Reverse ping test passed"
    else
        log_error "Reverse ping test failed"
    fi
    
    if docker exec nextcloud-collabora nc -z nextcloud-app 80 2>/dev/null; then
        log_success "Nextcloud port 80 is accessible from Collabora"
    else
        log_error "Nextcloud port 80 is not accessible from Collabora"
    fi
    
    echo ""
}

# Step 3: Test Collabora service endpoints
test_collabora_endpoints() {
    log "=== TESTING COLLABORA ENDPOINTS ==="
    
    # Test from host
    echo "Testing from host machine:"
    
    echo -n "Discovery endpoint: "
    if curl -s --connect-timeout 10 "http://localhost:9980/hosting/discovery" | head -1 | grep -q "<?xml"; then
        log_success "Working (XML response received)"
    else
        log_error "Not working or invalid response"
        echo "Response preview:"
        curl -s --connect-timeout 5 "http://localhost:9980/hosting/discovery" | head -3 || echo "No response"
    fi
    
    echo -n "Capabilities endpoint: "
    if curl -s --connect-timeout 10 "http://localhost:9980/hosting/capabilities" | grep -q "HasEditSupport"; then
        log_success "Working"
    else
        log_error "Not working"
    fi
    
    echo ""
    echo "Testing from Nextcloud container:"
    
    echo -n "Internal discovery endpoint: "
    if docker exec nextcloud-app curl -s --connect-timeout 10 "http://nextcloud-collabora:9980/hosting/discovery" | head -1 | grep -q "<?xml"; then
        log_success "Working from inside Nextcloud container"
    else 
        log_error "Not working from inside Nextcloud container"
    fi
    
    echo ""
}

# Step 4: Check Nextcloud app configuration
check_nextcloud_config() {
    log "=== CHECKING NEXTCLOUD CONFIGURATION ==="
    
    cd "$NEXTCLOUD_DIR"
    
    # Check if richdocuments app is installed
    echo "Richdocuments app status:"
    if $OCC_CMD app:list | grep -q "richdocuments"; then
        if $OCC_CMD app:list | grep "richdocuments" | grep -q "enabled"; then
            log_success "richdocuments app is installed and enabled"
        else
            log_warning "richdocuments app is installed but not enabled"
        fi
    else
        log_error "richdocuments app is not installed"
        return 1
    fi
    
    echo ""
    echo "Current WOPI configuration:"
    
    local wopi_url=$($OCC_CMD config:app:get richdocuments wopi_url 2>/dev/null || echo "")
    local public_wopi_url=$($OCC_CMD config:app:get richdocuments public_wopi_url 2>/dev/null || echo "")
    local wopi_allowlist=$($OCC_CMD config:app:get richdocuments wopi_allowlist 2>/dev/null || echo "")
    
    echo "  WOPI URL: ${wopi_url:-'Not set'}"
    if [ -n "$wopi_url" ]; then
        echo "    ✅ Internal WOPI URL configured"
    else
        echo "    ❌ Internal WOPI URL missing"
    fi
    
    echo "  Public WOPI URL: ${public_wopi_url:-'Not set'}"
    if [ -n "$public_wopi_url" ]; then
        if [[ "$public_wopi_url" == http://* ]]; then
            echo "    ✅ Public WOPI URL uses HTTP (correct for development)"
        else
            echo "    ⚠️  Public WOPI URL uses HTTPS (may cause connection issues)"
        fi
    else
        echo "    ❌ Public WOPI URL missing"
    fi
    
    echo "  WOPI Allowlist: ${wopi_allowlist:-'Not set'}"
    if [ -n "$wopi_allowlist" ]; then
        echo "    ✅ WOPI Allowlist configured (security warning resolved)"
    else
        echo "    ❌ WOPI Allowlist missing (will show security warning)"
    fi
    
    echo "  Callback URL: $($OCC_CMD config:app:get richdocuments wopi_callback_url 2>/dev/null || echo 'Not set')"
    echo "  SSL verification disabled: $($OCC_CMD config:app:get richdocuments disable_certificate_verification 2>/dev/null || echo 'Not set')"
    echo "  Timeout: $($OCC_CMD config:app:get richdocuments timeout 2>/dev/null || echo 'Not set')"
    echo ""
}

# Step 5: Analyze logs
analyze_logs() {
    log "=== ANALYZING LOGS ==="
    
    echo "Recent Collabora logs:"
    echo "========================"
    docker logs --tail 20 nextcloud-collabora 2>/dev/null || echo "Could not retrieve Collabora logs"
    echo ""
    
    echo "Recent Nextcloud logs (filtered for Collabora/WOPI):"
    echo "===================================================="
    if docker exec nextcloud-app test -f /var/www/html/data/nextcloud.log; then
        docker exec nextcloud-app grep -i "richdocuments\|collabora\|wopi\|office" /var/www/html/data/nextcloud.log 2>/dev/null | tail -10 || echo "No relevant logs found"
    else
        log_warning "Nextcloud log file not found"
    fi
    echo ""
}

# Step 6: Test document creation
test_document_creation() {
    log "=== TESTING DOCUMENT CREATION ==="
    
    cd "$NEXTCLOUD_DIR"
    
    echo "Attempting to test document creation capabilities..."
    
    # Check if we can query WOPI discovery
    echo "Testing WOPI discovery parsing:"
    if $OCC_CMD richdocuments:activate-config 2>&1 | grep -q "Collabora Online"; then
        log_success "WOPI discovery successful"
    else
        log_error "WOPI discovery failed"
        echo "Manual discovery test:"
        curl -s "http://localhost:9980/hosting/discovery" | grep -i "action.*edit" | head -3 || echo "No edit actions found"
    fi
    echo ""
}

# Step 7: Provide fix suggestions
suggest_fixes() {
    log "=== SUGGESTED FIXES ==="
    
    echo "Based on the diagnostics above, try these solutions:"
    echo ""
    echo "1. If containers are not running:"
    echo "   cd /opt/nextcloud && docker-compose down && docker-compose up -d"
    echo ""
    echo "2. If network connectivity fails:"
    echo "   docker network prune"
    echo "   docker-compose down && docker-compose up -d"
    echo ""
    echo "3. If Collabora endpoints don't work:"
    echo "   docker restart nextcloud-collabora"
    echo "   Wait 30 seconds, then test again"
    echo ""
    echo "4. If WOPI configuration is wrong:"
    echo "   /opt/bin/nextcloud-collabora-setup.sh configure"
    echo ""
    echo "5. If richdocuments app has issues:"
    echo "   /opt/bin/nextcloud-occ.sh app:disable richdocuments"
    echo "   /opt/bin/nextcloud-occ.sh app:enable richdocuments"
    echo "   /opt/bin/nextcloud-collabora-setup.sh configure"
    echo ""
    echo "6. Complete reset (nuclear option):"
    echo "   cd /opt/nextcloud"
    echo "   docker-compose down -v"
    echo "   docker-compose up -d"
    echo "   Wait for startup, then run app installation again"
}

# Main function
main() {
    log "🔍 Starting comprehensive Collabora debugging..."
    echo ""
    
    check_docker_setup || exit 1
    test_network_connectivity
    test_collabora_endpoints
    check_nextcloud_config
    analyze_logs
    test_document_creation
    suggest_fixes
    
    echo ""
    log_success "🏁 Debugging complete!"
    echo ""
    echo "Next steps:"
    echo "1. Review the output above to identify the specific issue"
    echo "2. Try the suggested fixes in order"
    echo "3. Re-run this script after each fix to verify progress"
    echo "4. If issues persist, check the full Collabora logs with:"
    echo "   docker logs nextcloud-collabora"
}

# Run main function
main "$@"
