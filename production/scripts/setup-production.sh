#!/bin/bash
# Nextcloud production setup script
set -euo pipefail

log() { echo "[SETUP] $1"; }

main() {
    log "Starting production setup..."
    
    use_internal_https=false
    [[ "${1:-}" == "--internal-https" ]] && use_internal_https=true
    
    cd /opt/nextcloud
    
    # Setup .env
    if [[ ! -f .env ]]; then
        [[ ! -f .env.example ]] && { echo "ERROR: .env.example not found" >&2; exit 1; }
        cp .env.example .env
        echo "ERROR: Configure .env and run again" >&2; exit 1
    fi
    
    source .env
    
    # Validate
    for var in DOMAIN ACME_EMAIL NEXTCLOUD_ADMIN_PASSWORD POSTGRES_PASSWORD REDIS_PASSWORD; do
        [[ -z "${!var:-}" ]] && { echo "ERROR: $var not set in .env" >&2; exit 1; }
    done
    
    # Setup
    docker network create traefik 2>/dev/null || true
    
    if [[ -z "${TRAEFIK_AUTH:-}" ]] && command -v htpasswd >/dev/null; then
        auth_hash=$(htpasswd -nb admin "$NEXTCLOUD_ADMIN_PASSWORD")
        sed -i "s|^TRAEFIK_AUTH=.*|TRAEFIK_AUTH=${auth_hash}|" .env
    fi
    
    mkdir -p config data apps backups
    chown -R core:core .
    chown -R 33:33 config data apps
    chmod 600 .env
    
    if [[ "$use_internal_https" == true ]]; then
        log "Setting up internal HTTPS..."
        /opt/bin/generate-internal-certs.sh
    fi
    
    log "✅ Setup complete!"
    if [[ "$use_internal_https" == true ]]; then
        echo "Run: docker-compose -f docker-compose.internal-https.yml up -d"
    else
        echo "Run: docker-compose up -d"
    fi
    echo "Access: https://${DOMAIN}"
}

main "$@"
