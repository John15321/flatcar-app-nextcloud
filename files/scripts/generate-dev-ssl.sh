#!/bin/bash
# Generate self-signed SSL certificates for development

SSL_DIR="/opt/nextcloud/ssl"
mkdir -p "$SSL_DIR"

echo "Generating self-signed SSL certificate for development..."
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
    -keyout "$SSL_DIR/key.pem" \
    -out "$SSL_DIR/cert.pem" \
    -subj "/C=US/ST=Dev/L=Local/O=Development/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1,IP:10.0.2.15"

chmod 600 "$SSL_DIR"/*.pem
echo "SSL certificate generated at $SSL_DIR"