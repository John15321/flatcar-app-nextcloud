#!/bin/bash

# Development SSL Certificate Generator
SSL_DIR="./ssl"
mkdir -p "$SSL_DIR"

echo "Generating self-signed certificate for development..."

# Generate self-signed certificate for development
openssl req -x509 -newkey rsa:2048 \
    -keyout "$SSL_DIR/key.pem" \
    -out "$SSL_DIR/cert.pem" \
    -days 365 -nodes \
    -subj "/C=US/ST=Dev/L=Local/O=Development/CN=localhost"

chmod 600 "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"

echo "✅ Self-signed certificate generated:"
echo "   - Certificate: $SSL_DIR/cert.pem"
echo "   - Private Key: $SSL_DIR/key.pem"
echo "   - Valid for: 365 days"
echo ""
echo "⚠️  Browser will show security warnings (this is normal for self-signed certificates)"
