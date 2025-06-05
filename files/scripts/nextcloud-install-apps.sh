#!/bin/bash

# Nextcloud Apps Installation Script
# Automatically installs essential development and productivity apps
# Uses OCC command to install and enable apps

set -euo pipefail

# Configuration
SCRIPT_DIR="$(dirname "$0")"
NEXTCLOUD_DIR="/opt/nextcloud"
OCC_CMD="/opt/bin/nextcloud-occ.sh"
MAX_RETRIES=30
RETRY_DELAY=10

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

# Wait for Nextcloud to be ready
wait_for_nextcloud() {
    log "Waiting for Nextcloud to be ready..."
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if $OCC_CMD status >/dev/null 2>&1; then
            log_success "Nextcloud is ready!"
            return 0
        fi
        
        retries=$((retries + 1))
        log "Attempt $retries/$MAX_RETRIES - Nextcloud not ready yet, waiting ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    done
    
    log_error "Nextcloud failed to become ready after $MAX_RETRIES attempts"
    return 1
}

# Install an app with retry logic
install_app() {
    local app_name="$1"
    local app_description="$2"
    local retries=0
    
    log "Installing $app_description ($app_name)..."
    
    # Check if app is already installed
    if $OCC_CMD app:list | grep -q "^  - $app_name:"; then
        log_success "$app_description is already installed"
        return 0
    fi
    
    while [ $retries -lt 3 ]; do
        if $OCC_CMD app:install "$app_name" >/dev/null 2>&1; then
            log_success "Installed $app_description"
            return 0
        fi
        
        retries=$((retries + 1))
        log_warning "Failed to install $app_description (attempt $retries/3)"
        
        if [ $retries -lt 3 ]; then
            sleep 5
        fi
    done
    
    log_error "Failed to install $app_description after 3 attempts"
    return 1
}

# Enable an app
enable_app() {
    local app_name="$1"
    local app_description="$2"
    
    log "Enabling $app_description ($app_name)..."
    
    if $OCC_CMD app:enable "$app_name" >/dev/null 2>&1; then
        log_success "Enabled $app_description"
        return 0
    else
        log_error "Failed to enable $app_description"
        return 1
    fi
}

# Configure Collabora if it's available
configure_collabora() {
    log "Configuring Collabora integration..."
    
    # Check if Collabora container is running
    if docker ps --format '{{.Names}}' | grep -q "nextcloud-collabora"; then
        log "Collabora container detected, configuring integration..."
        
        # Clear any existing configuration first to avoid conflicts
        $OCC_CMD config:app:delete richdocuments wopi_url 2>/dev/null || true
        $OCC_CMD config:app:delete richdocuments public_wopi_url 2>/dev/null || true
        $OCC_CMD config:app:delete richdocuments wopi_callback_url 2>/dev/null || true
        $OCC_CMD config:app:delete richdocuments wopi_allowlist 2>/dev/null || true
        
        # Set Collabora server URL for internal communication
        $OCC_CMD config:app:set richdocuments wopi_url --value="http://nextcloud-collabora:9980" || true
        
        # Set public URL for browser access (HTTP, not HTTPS!)
        $OCC_CMD config:app:set richdocuments public_wopi_url --value="http://localhost:9980" || true
        
        # Set WOPI allowlist to prevent security warnings
        $OCC_CMD config:app:set richdocuments wopi_allowlist --value="127.0.0.1,::1,localhost,nextcloud-app" || true
        
        # Disable SSL verification for development
        $OCC_CMD config:app:set richdocuments disable_certificate_verification --value="yes" || true
        
        # Enable WOPI callback
        $OCC_CMD config:app:set richdocuments wopi_callback_url --value="http://nextcloud-app:80" || true
        
        # Set additional settings for development
        $OCC_CMD config:app:set richdocuments edit_groups --value="" || true
        $OCC_CMD config:app:set richdocuments use_groups --value="" || true
        $OCC_CMD config:app:set richdocuments timeout --value="30" || true
        
        # Force refresh of discovery info
        $OCC_CMD config:app:delete richdocuments discovery_refresh_timestamp 2>/dev/null || true
        
        # Test connection with more time and better error handling
        log "Testing Collabora connection..."
        sleep 10  # Give Collabora more time to fully start
        
        local test_attempts=0
        local max_attempts=3
        
        while [ $test_attempts -lt $max_attempts ]; do
            if curl -s --connect-timeout 10 "http://localhost:9980/hosting/discovery" > /dev/null; then
                log_success "Collabora connection test passed"
                break
            else
                test_attempts=$((test_attempts + 1))
                if [ $test_attempts -lt $max_attempts ]; then
                    log_warning "Collabora connection test failed (attempt $test_attempts/$max_attempts), retrying..."
                    sleep 5
                else
                    log_warning "Collabora connection test failed after $max_attempts attempts"
                    log_warning "This may be normal during initial startup - Collabora will be available shortly"
                fi
            fi
        done
        
        log_success "Collabora integration configured"
    else
        log_warning "Collabora container not running, skipping integration setup"
    fi
}

# Main installation process
main() {
    log "🚀 Starting Nextcloud apps installation..."
    
    cd "$NEXTCLOUD_DIR"
    
    # Wait for Nextcloud to be ready
    if ! wait_for_nextcloud; then
        log_error "Cannot proceed with app installation - Nextcloud is not ready"
        exit 1
    fi
    
    # List of essential apps to install
    # Format: "app_name:App Description"
    local apps=(
        "richdocuments:Collabora Online (Office Documents)"
        "files_external:External Storage Support"
        "user_ldap:LDAP Integration"
        "two_factor_totp:Two-Factor Authentication (TOTP)"
        "files_downloadactivity:Download Activity Tracking"
        "admin_audit:Admin Audit Logging"
        "files_accesscontrol:File Access Control"
        "bruteforcesettings:Brute Force Protection"
        "suspicious_login:Suspicious Login Detection"
        "files_retention:File Retention"
        "groupfolders:Group Folders"
        "deck:Kanban Board"
        "notes:Notes"
        "contacts:Contacts"
        "calendar:Calendar"
        "mail:Mail"
        "tasks:Tasks"
    )
    
    # Track installation results
    local installed_count=0
    local failed_count=0
    
    # Install apps
    for app_entry in "${apps[@]}"; do
        IFS=':' read -r app_name app_description <<< "$app_entry"
        
        if install_app "$app_name" "$app_description"; then
            enable_app "$app_name" "$app_description"
            installed_count=$((installed_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
    done
    
    # Configure Collabora if richdocuments was installed
    if $OCC_CMD app:list | grep -q "^  - richdocuments:"; then
        configure_collabora
    fi
    
    # Summary
    log_success "🎉 App installation completed!"
    log_success "✅ Successfully installed: $installed_count apps"
    
    if [ $failed_count -gt 0 ]; then
        log_warning "⚠️  Failed to install: $failed_count apps"
    fi
    
    # List all enabled apps
    log "📋 Currently enabled apps:"
    $OCC_CMD app:list | grep "^  - " | sed 's/^  - /    ✓ /'
    
    log_success "🏁 All done! Your Nextcloud instance is ready for development."
}

# Run main function
main "$@"
