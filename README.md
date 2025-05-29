# Nextcloud on Flatcar Container Linux

A comprehensive, production-ready Nextcloud deployment on Flatcar Container Linux with PostgreSQL, Redis, and Nginx. This setup provides both cloud-ready production configuration and local development environment.

## 🏗️ Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│                    Flatcar Container Linux                    │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                Docker Compose Stack                     │  │
│  │                                                         │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐  │  │
│  │  │  Nginx   │  │Nextcloud │  │PostgreSQL│  │  Redis  │  │  │
│  │  │  Proxy   │  │   App    │  │Database  │  │  Cache  │  │  │
│  │  │  :80/443 │  │   :9000  │  │   :5432  │  │  :6379  │  │  │
│  │  └─────┬────┘  └─────┬────┘  └─────┬────┘  └────┬────┘  │  │
│  │        │             │             │            │       │  │
│  │  ┌─────┴─────────────┴─────────────┴────────────┴────┐  │  │
│  │  │           Internal Docker Network                 │  │  │
│  │  │              (nextcloud_network)                  │  │  │
│  │  └───────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                  Persistent Storage                     │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │  │
│  │  │ Nextcloud   │  │ PostgreSQL  │  │     Nginx       │  │  │
│  │  │    Data     │  │    Data     │  │  Certificates   │  │  │
│  │  │   Volume    │  │   Volume    │  │    Volume       │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Flatcar Container Linux** - Immutable, container-optimized OS
- **Butane** - For converting YAML to Ignition format
- **SSH access** to your Flatcar instance

### Production Deployment (Cloud)

1. **Prepare the configuration:**
   ```bash
   # Download and validate the production configuration
   butane --pretty --strict nextcloud-production.yaml > ignition.json
   ```

2. **Deploy to cloud provider:**
   ```bash
   # For cloud deployment, use the ignition.json with your provider
   # Examples:
   # - AWS: Use as user-data in EC2 launch
   # - DigitalOcean: Use as user-data in Droplet creation
   # - Azure: Use as custom-data in VM creation
   ```

3. **Initial setup:**
   ```bash
   # SSH to your instance and verify services
   ssh core@your-server-ip
   docker ps
   ```

### Development Deployment (Local)

1. **Start local VM:**
   ```bash
   # Use the enhanced QEMU script with port forwarding
   ./flatcar_production_qemu.sh
   ```

2. **Deploy development configuration:**
   ```bash
   # Convert development config to Ignition
   butane --pretty --strict nextcloud-development.yaml > dev-ignition.json
   
   # Copy to VM and apply (details in VM setup section)
   ```

## 📁 Project Structure

```
flatcar-app-nextcloud/
├── README.md                      # This comprehensive guide
├── docker-compose.yml             # Multi-service container orchestration
├── nextcloud-production.yaml      # Cloud-ready Flatcar configuration
├── nextcloud-development.yaml     # Local development configuration
├── flatcar_production_qemu.sh     # Enhanced VM launcher with port forwarding
├── nginx/
│   └── nextcloud.conf             # Optimized Nginx reverse proxy config
└── scripts/
    ├── backup.sh                  # Automated backup script
    └── update.sh                  # System and container update script
```

## 🔧 Configuration Details

### Production vs Development

| Aspect | Production | Development |
|--------|------------|-------------|
| **SSL/TLS** | Let's Encrypt automatic | Self-signed certificates |
| **Ports** | 80, 443 | 8080, 8443 |
| **Database** | Persistent volumes | Persistent volumes |
| **Performance** | Optimized for scale | Optimized for development |
| **Security** | Hardened | Development-friendly |
| **Monitoring** | Full logging | Simplified logging |

### Core Services Explained

#### 🌐 Nginx Reverse Proxy
- **Purpose**: Handles SSL termination, static file serving, and request routing
- **Why**: Offloads encryption/decryption from Nextcloud, improves performance
- **Features**: HTTP/2, gzip compression, security headers, rate limiting

#### 📱 Nextcloud Application
- **Purpose**: The main Nextcloud PHP-FPM application
- **Why PHP-FPM**: Better performance and resource management than Apache
- **Features**: File sync, collaboration, app ecosystem

#### 🗄️ PostgreSQL Database
- **Purpose**: Reliable, ACID-compliant data storage
- **Why PostgreSQL over MySQL**: Better performance with Nextcloud, superior JSON support, more robust
- **Features**: Connection pooling, automatic backups, performance tuning

#### ⚡ Redis Cache
- **Purpose**: In-memory caching for session data and file locking
- **Why**: Dramatically improves performance, especially for multiple users
- **Features**: Persistent storage, memory optimization

## 🔐 Security Features

### Network Security
- **Internal Docker network**: Services communicate privately
- **Exposed ports**: Only HTTP/HTTPS exposed to public
- **SSL/TLS**: End-to-end encryption in production

### Container Security
- **Non-root execution**: All containers run as non-privileged users where possible
- **Resource limits**: Memory and CPU constraints prevent resource exhaustion
- **Health checks**: Automatic service recovery

### Data Security
- **Persistent volumes**: Data survives container restarts
- **Regular backups**: Automated backup scripts included
- **Database encryption**: PostgreSQL supports encryption at rest

## 🚀 Deployment Guide

### Cloud Deployment (Production)

#### Step 1: Prepare Ignition Configuration
```bash
# Validate and convert the production configuration
butane --pretty --strict nextcloud-production.yaml > ignition.json

# Verify the output
jq . ignition.json
```

#### Step 2: Deploy to Cloud Provider

**AWS EC2:**
```bash
# Use ignition.json as user-data when launching instance
aws ec2 run-instances \
  --image-id ami-xxx \
  --instance-type t3.medium \
  --user-data file://ignition.json \
  --security-group-ids sg-xxx
```

**DigitalOcean:**
```bash
# Create droplet with user-data
doctl compute droplet create nextcloud \
  --image flatcar-stable \
  --size s-2vcpu-4gb \
  --user-data-file ignition.json
```

#### Step 3: Initial Configuration
```bash
# SSH to your instance
ssh core@your-server-ip

# Verify services are running
docker ps
docker-compose -f /opt/nextcloud/docker-compose.yml logs

# Access Nextcloud at https://your-domain.com
```

### Local Development Deployment

#### Step 1: Start Development VM
```bash
# Launch VM with port forwarding
./flatcar_production_qemu.sh

# VM will be accessible at:
# - HTTP: http://localhost:8080
# - HTTPS: https://localhost:8443
# - SSH: ssh -p 2222 core@localhost
```

#### Step 2: Deploy Development Configuration
```bash
# Convert development config
butane --pretty --strict nextcloud-development.yaml > dev-ignition.json

# Copy to VM
scp -P 2222 dev-ignition.json core@localhost:/home/core/

# SSH to VM and apply
ssh -p 2222 core@localhost
sudo cp dev-ignition.json /var/lib/flatcar-install/ignition.json
sudo systemctl reboot
```

## 🛠️ Management and Maintenance

### Backup Strategy
```bash
# Run automated backup
./scripts/backup.sh

# Manual database backup
docker exec nextcloud_postgres pg_dump -U nextcloud nextcloud > backup.sql

# Manual data backup
docker exec nextcloud_app tar -czf - /var/www/html/data > data_backup.tar.gz
```

### Updates and Maintenance
```bash
# Update system and containers
./scripts/update.sh

# Check service health
docker-compose -f /opt/nextcloud/docker-compose.yml ps
docker-compose -f /opt/nextcloud/docker-compose.yml logs --tail=50
```

### Monitoring and Troubleshooting
```bash
# View service logs
journalctl -u docker-compose@nextcloud -f

# Check container resources
docker stats

# Database connection test
docker exec nextcloud_postgres psql -U nextcloud -d nextcloud -c "\dt"
```

## 📊 Performance Optimization

### PostgreSQL Tuning
The configuration includes optimized PostgreSQL settings:
- **shared_buffers**: 256MB for better caching
- **effective_cache_size**: 1GB to utilize system memory
- **work_mem**: 4MB for query operations
- **maintenance_work_mem**: 64MB for maintenance tasks

### Nginx Optimization
- **worker_processes**: Auto-detected based on CPU cores
- **client_max_body_size**: 10G for large file uploads
- **gzip compression**: Enabled for better bandwidth usage
- **HTTP/2**: Enabled for improved performance

### Redis Configuration
- **maxmemory-policy**: allkeys-lru for automatic memory management
- **Persistent storage**: Ensures cache survives restarts

## 🔍 Troubleshooting Guide

### Common Issues

#### Services Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check compose file syntax
docker-compose -f /opt/nextcloud/docker-compose.yml config

# View detailed logs
docker-compose -f /opt/nextcloud/docker-compose.yml logs
```

#### Database Connection Issues
```bash
# Test PostgreSQL connectivity
docker exec nextcloud_postgres pg_isready -U nextcloud

# Check database logs
docker logs nextcloud_postgres
```

#### SSL Certificate Issues
```bash
# Check nginx configuration
docker exec nextcloud_nginx nginx -t

# View certificate status
docker exec nextcloud_nginx openssl x509 -in /etc/ssl/certs/nextcloud.crt -text -noout
```

## 🤝 Contributing

### Development Workflow
1. Test changes in development environment first
2. Validate configurations with Butane
3. Document architectural decisions in code comments
4. Update this README with any new features

### Configuration Principles
- **Security by default**: All configurations prioritize security
- **Documentation first**: Every setting includes "why" explanations
- **Production ready**: Configurations work in real-world scenarios
- **Comprehensible**: Clear naming and extensive comments

## 📚 Additional Resources

- [Flatcar Container Linux Documentation](https://kinvolk.io/docs/flatcar-container-linux/latest/)
- [Nextcloud Administration Manual](https://docs.nextcloud.com/server/latest/admin_manual/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Built with ❤️ for reliable, secure, and scalable Nextcloud deployments on Flatcar Container Linux.**
