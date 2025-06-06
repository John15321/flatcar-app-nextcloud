#!/bin/bash
# Generate secure passwords for Nextcloud production
set -euo pipefail

log() { echo "[SECRETS] $1"; }

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-${1:-32}
}

generate_htpasswd() {
    if command -v htpasswd >/dev/null; then
        htpasswd -nb "$1" "$2" 2>/dev/null
    else
        echo "admin:\$2y\$10\$MANUAL_SETUP_REQUIRED"
    fi
}

main() {
    log "Generating secure passwords..."
    
    nextcloud_admin_pass=$(generate_password 24)
    postgres_pass=$(generate_password 32)
    redis_pass=$(generate_password 32)
    collabora_pass=$(generate_password 24)
    traefik_auth=$(generate_htpasswd "admin" "$nextcloud_admin_pass")
    
    echo "# Generated passwords (save securely!)"
    echo "NEXTCLOUD_ADMIN_USER=admin"
    echo "NEXTCLOUD_ADMIN_PASSWORD=$nextcloud_admin_pass"
    echo "POSTGRES_PASSWORD=$postgres_pass"
    echo "REDIS_PASSWORD=$redis_pass"
    echo "COLLABORA_ADMIN_PASSWORD=$collabora_pass"
    echo "TRAEFIK_AUTH=$traefik_auth"
    echo ""
    
    # Update .env if exists and user confirms
    if [[ -f "/opt/nextcloud/.env" ]]; then
        read -p "Update /opt/nextcloud/.env file? (y/N): " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            cp "/opt/nextcloud/.env" "/opt/nextcloud/.env.backup.$(date +%Y%m%d_%H%M%S)"
            sed -i "s|^NEXTCLOUD_ADMIN_PASSWORD=.*|NEXTCLOUD_ADMIN_PASSWORD=$nextcloud_admin_pass|" "/opt/nextcloud/.env"
            sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$postgres_pass|" "/opt/nextcloud/.env"
            sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=$redis_pass|" "/opt/nextcloud/.env"
            sed -i "s|^COLLABORA_ADMIN_PASSWORD=.*|COLLABORA_ADMIN_PASSWORD=$collabora_pass|" "/opt/nextcloud/.env"
            sed -i "s|^TRAEFIK_AUTH=.*|TRAEFIK_AUTH=$traefik_auth|" "/opt/nextcloud/.env"
            chmod 600 "/opt/nextcloud/.env"
            log "✅ Environment file updated!"
        fi
    fi
}

main "$@"
