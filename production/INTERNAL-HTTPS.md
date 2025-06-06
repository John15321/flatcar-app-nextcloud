# Internal HTTPS Configuration Guide

This guide explains how to deploy Nextcloud with end-to-end HTTPS encryption, including internal container-to-container communication.

## Architecture Overview

### Standard Production Setup
- **External**: HTTPS (Let's Encrypt) via Traefik
- **Internal**: HTTP between containers
- **Security**: SSL termination at reverse proxy

### Internal HTTPS Setup  
- **External**: HTTPS (Let's Encrypt) via Traefik
- **Internal**: HTTPS with self-signed certificates
- **Security**: End-to-end encryption

## Benefits of Internal HTTPS

1. **Defense in Depth**: Encryption even if container network is compromised
2. **Compliance**: Meets strict security requirements (SOC2, HIPAA, etc.)
3. **Network Security**: Protection against internal traffic interception
4. **Future-Proof**: Ready for service mesh integration

## Implementation

### 1. Certificate Management

The setup includes an automated certificate generation system:

```bash
# Internal Certificate Authority
- ca.crt/ca.key          # Root CA for internal services
- nextcloud-app.crt/key  # Nextcloud Apache SSL certificate
- collabora.crt/key      # Collabora Online SSL certificate  
- postgres.crt/key       # PostgreSQL TLS certificate
- redis.crt/key          # Redis TLS certificate
```

### 2. Service Configuration

Each service is configured for HTTPS:

**Nextcloud (Apache)**:
- SSL-enabled Apache with internal certificate
- HTTPS-only communication
- Modern TLS configuration (TLS 1.2+)

**Collabora Online**:
- Internal SSL enabled with custom certificate
- HTTPS communication with Nextcloud
- Secure document editing protocols

**PostgreSQL**:
- TLS-enabled database connections
- Certificate-based authentication
- Encrypted data transmission

**Redis**:
- TLS-enabled caching
- Encrypted session storage
- Secure key-value operations

### 3. Network Security

```yaml
networks:
  nextcloud-internal:
    driver: bridge
    internal: false  # Allows HTTPS but isolates from external
    ipam:
      config:
        - subnet: 172.20.0.0/16  # Dedicated internal subnet
```

## Deployment

### Option 1: Enhanced Production Deployment

```bash
# Use the internal HTTPS configuration
cd production
cp configs/docker-compose.internal-https.yml configs/docker-compose.yml
cp configs/traefik/traefik-internal-https.yml configs/traefik/traefik.yml

# Deploy as usual
make ignition-prod
# Deploy to server with generated prod.ign
```

### Option 2: Hybrid Approach

Keep external-only HTTPS for simpler deployment:

```bash
# Use standard production configuration
cd production
# Standard deployment - HTTPS external, HTTP internal
```

## Performance Considerations

**Overhead**: Internal HTTPS adds ~5-10% CPU overhead for TLS encryption/decryption

**Memory**: Additional ~50MB RAM for certificate management

**Latency**: +1-2ms for internal HTTPS handshakes

**Trade-off**: Slightly higher resource usage for significantly better security

## Monitoring & Troubleshooting

### Certificate Validation

```bash
# Check internal certificate validity
docker exec nextcloud-app openssl x509 -in /etc/ssl/internal/nextcloud-app.crt -text -noout

# Verify certificate chain
docker exec nextcloud-app openssl verify -CAfile /etc/ssl/internal/ca.crt /etc/ssl/internal/nextcloud-app.crt
```

### Connection Testing

```bash
# Test internal HTTPS connectivity
docker exec nextcloud-app curl -k https://nextcloud-collabora:9980/hosting/discovery

# Test PostgreSQL TLS
docker exec nextcloud-app psql "sslmode=require host=db user=${POSTGRES_USER} dbname=${POSTGRES_DB}"
```

### Certificate Renewal

Certificates are automatically generated with 365-day validity. To renew:

```bash
# Regenerate all internal certificates
docker-compose down
docker volume rm nextcloud_internal_certs
docker-compose up -d
```

## Security Benefits Summary

| Feature | Standard HTTPS | Internal HTTPS |
|---------|---------------|----------------|
| External Traffic | ✅ Encrypted | ✅ Encrypted |
| Internal Traffic | ❌ Plain HTTP | ✅ Encrypted |
| Database Connections | ❌ Plain TCP | ✅ TLS Encrypted |
| Cache Communication | ❌ Plain TCP | ✅ TLS Encrypted |
| Network Isolation | ✅ Docker Networks | ✅ + TLS |
| Compliance Ready | ⚠️ Partial | ✅ Full |

Choose internal HTTPS for maximum security or standard HTTPS for simpler deployment.
