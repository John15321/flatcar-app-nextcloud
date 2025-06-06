#!/bin/bash
# =========================================================================
# STANDALONE SERVER INSTALLATION SCRIPT
# =========================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INSTALL] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[INSTALL] $1${NC}"
}

error() {
    echo -e "${RED}[INSTALL] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INSTALL] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is required but not installed"
    fi
    
    # Check if we have internet connectivity
    if ! curl -s --connect-timeout 5 google.com >/dev/null; then
        error "Internet connectivity is required"
    fi
    
    # Check available disk space (minimum 10GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 10485760 ]]; then  # 10GB in KB
        warn "Less than 10GB available disk space. Consider expanding storage."
    fi
    
    log "System requirements check passed"
}

# Create directory structure
setup_directories() {
    log "Setting up directory structure..."
    
    local base_dir="/opt/nextcloud"
    sudo mkdir -p "$base_dir"/{config,data,apps,traefik,backups}
    sudo mkdir -p /opt/bin
    sudo mkdir -p /var/log/nextcloud
    
    # Set proper ownership
    sudo chown -R "$USER:$USER" "$base_dir"
    sudo chown -R "$USER:$USER" /opt/bin
    sudo chown -R "$USER:$USER" /var/log/nextcloud
    
    log "Directory structure created"
}

# Download and setup files
setup_files() {
    log "Setting up configuration files..."
    
    local base_dir="/opt/nextcloud"
    local repo_url="https://raw.githubusercontent.com/yourusername/flatcar-app-nextcloud/main/production"
    
    # Download configuration files
    curl -L "$repo_url/configs/docker-compose.prod.yml" -o "$base_dir/docker-compose.yml"
    curl -L "$repo_url/configs/.env.example" -o "$base_dir/.env.example"
    curl -L "$repo_url/configs/traefik/traefik.yml" -o "$base_dir/traefik/traefik.yml"
    curl -L "$repo_url/configs/traefik/dynamic.yml" -o "$base_dir/traefik/dynamic.yml"
    
    # Download scripts
    curl -L "$repo_url/scripts/setup-production.sh" -o /opt/bin/setup-production.sh
    curl -L "$repo_url/scripts/generate-secrets.sh" -o /opt/bin/generate-secrets.sh
    curl -L "$repo_url/scripts/backup-nextcloud.sh" -o /opt/bin/backup-nextcloud.sh
    curl -L "$repo_url/scripts/update-system.sh" -o /opt/bin/update-system.sh
    
    # Make scripts executable
    chmod +x /opt/bin/*.sh
    
    log "Configuration files downloaded"
}

# Setup Docker networks
setup_docker() {
    log "Setting up Docker environment..."
    
    # Create Traefik network if it doesn't exist
    if ! docker network ls | grep -q "traefik"; then
        docker network create traefik
        log "Created Traefik network"
    fi
    
    # Pull required images
    cd /opt/nextcloud
    docker-compose pull
    
    log "Docker environment ready"
}

# Setup environment configuration
setup_environment() {
    log "Setting up environment configuration..."
    
    local base_dir="/opt/nextcloud"
    
    if [[ ! -f "$base_dir/.env" ]]; then
        cp "$base_dir/.env.example" "$base_dir/.env"
        
        echo ""
        warn "IMPORTANT: Configure $base_dir/.env with your settings"
        warn "Run: /opt/bin/generate-secrets.sh to generate secure passwords"
        echo ""
        
        # Prompt for basic configuration
        read -p "Enter your domain name (or press Enter to configure later): " domain
        if [[ -n "$domain" ]]; then
            sed -i "s/nextcloud.yourdomain.com/$domain/" "$base_dir/.env"
        fi
        
        read -p "Enter your email for SSL certificates (or press Enter to configure later): " email
        if [[ -n "$email" ]]; then
            sed -i "s/admin@yourdomain.com/$email/" "$base_dir/.env"
        fi
    fi
    
    # Set secure permissions
    chmod 600 "$base_dir/.env"
    
    log "Environment configuration ready"
}

# Setup systemd service
setup_systemd() {
    log "Setting up systemd service..."
    
    cat << 'EOF' | sudo tee /etc/systemd/system/nextcloud-production.service >/dev/null
[Unit]
Description=Nextcloud Production Environment
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/nextcloud
ExecStartPre=/bin/bash /opt/bin/setup-production.sh
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nextcloud-production.service
    
    log "Systemd service configured"
}

# Setup backup schedule
setup_backups() {
    log "Setting up backup schedule..."
    
    # Create backup service
    cat << 'EOF' | sudo tee /etc/systemd/system/nextcloud-backup.service >/dev/null
[Unit]
Description=Nextcloud Backup Service

[Service]
Type=oneshot
ExecStart=/opt/bin/backup-nextcloud.sh
User=core
EOF

    # Create backup timer
    cat << 'EOF' | sudo tee /etc/systemd/system/nextcloud-backup.timer >/dev/null
[Unit]
Description=Daily Nextcloud Backup

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nextcloud-backup.timer
    sudo systemctl start nextcloud-backup.timer
    
    log "Backup schedule configured"
}

# Main installation function
main() {
    echo "🚀 Nextcloud Production Installation"
    echo "===================================="
    echo ""
    
    check_root
    check_requirements
    setup_directories
    setup_files
    setup_docker
    setup_environment
    setup_systemd
    setup_backups
    
    echo ""
    log "🎉 Installation completed successfully!"
    echo ""
    info "Next steps:"
    info "1. Configure /opt/nextcloud/.env with your settings"
    info "2. Generate secure passwords: /opt/bin/generate-secrets.sh"
    info "3. Start services: sudo systemctl start nextcloud-production"
    info "4. Check status: sudo systemctl status nextcloud-production"
    echo ""
    warn "Important: Make sure to configure your domain's DNS to point to this server"
    warn "SSL certificates will be automatically generated via Let's Encrypt"
}

# Run main function
main "$@"
