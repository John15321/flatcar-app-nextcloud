#!/bin/bash
# Generate internal SSL certificates for container communication
set -euo pipefail

CERT_DIR="/certs"
VALIDITY_DAYS=365

log() { echo "[CERT-GEN] $1"; }

generate_ca() {
    log "Generating CA..."
    openssl genrsa -out "$CERT_DIR/ca.key" 4096
    openssl req -new -x509 -days $VALIDITY_DAYS -key "$CERT_DIR/ca.key" \
        -out "$CERT_DIR/ca.crt" \
        -subj "/C=US/ST=CA/L=SF/O=Nextcloud/OU=Internal/CN=Nextcloud Internal CA"
}

generate_service_cert() {
    local service="$1"
    local cn="$2"
    local san="${3:-}"
    
    log "Generating cert for $service..."
    openssl genrsa -out "$CERT_DIR/$service.key" 2048
    openssl req -new -key "$CERT_DIR/$service.key" \
        -out "$CERT_DIR/$service.csr" \
        -subj "/C=US/ST=CA/L=SF/O=Nextcloud/OU=Internal/CN=$cn"
    
    if [[ -n "$san" ]]; then
        echo "subjectAltName=$san" > "$CERT_DIR/$service.ext"
        echo "keyUsage=keyEncipherment,dataEncipherment" >> "$CERT_DIR/$service.ext"
        echo "extendedKeyUsage=serverAuth,clientAuth" >> "$CERT_DIR/$service.ext"
        
        openssl x509 -req -in "$CERT_DIR/$service.csr" \
            -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" \
            -CAcreateserial -out "$CERT_DIR/$service.crt" \
            -days $VALIDITY_DAYS -extensions v3_req -extfile "$CERT_DIR/$service.ext"
        rm "$CERT_DIR/$service.ext"
    else
        openssl x509 -req -in "$CERT_DIR/$service.csr" \
            -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" \
            -CAcreateserial -out "$CERT_DIR/$service.crt" \
            -days $VALIDITY_DAYS
    fi
    
    rm "$CERT_DIR/$service.csr"
}

main() {
    mkdir -p "$CERT_DIR" && cd "$CERT_DIR"
    
    if [[ -f "ca.crt" && -f "nextcloud-app.crt" ]]; then
        log "Certificates exist, skipping"
        return 0
    fi
    
    generate_ca
    
    generate_service_cert "nextcloud-app" "nextcloud-app" "DNS:nextcloud-app,DNS:localhost,IP:127.0.0.1"
    generate_service_cert "collabora" "collabora" "DNS:nextcloud-collabora,DNS:collabora,DNS:localhost"
    generate_service_cert "postgres" "postgres" "DNS:nextcloud-db,DNS:db,DNS:localhost"
    generate_service_cert "redis" "redis" "DNS:nextcloud-redis,DNS:redis,DNS:localhost"
    generate_service_cert "traefik" "traefik" "DNS:nextcloud-traefik,DNS:traefik,DNS:localhost"
    
    chmod 644 *.crt *.pem 2>/dev/null || true
    chmod 600 *.key
    
    log "✅ All certificates generated (valid $VALIDITY_DAYS days)"
}

main "$@"
