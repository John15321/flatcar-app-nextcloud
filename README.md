# Nextcloud on Flatcar Container Linux

[![YAML Validation](https://github.com/your-username/flatcar-app-nextcloud/actions/workflows/validate-yaml.yml/badge.svg)](https://github.com/your-username/flatcar-app-nextcloud/actions/workflows/validate-yaml.yml)

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

### 🔧 Technical Implementation

This project leverages **Flatcar Container Linux** features:

- **Docker Compose Binary**: Flatcar doesn't include Docker Compose by default. We automatically download the latest Docker Compose binary to `/opt/bin/` during first boot, making it available system-wide.
- **Immutable OS**: The base system is read-only, ensuring consistency and security.
- **Butane Configuration**: Human-readable YAML that compiles to Ignition JSON for system provisioning.
- **Systemd Integration**: All services managed through systemd units for reliable startup and dependency handling.

The setup automatically downloads the latest Docker Compose binary from the official Docker releases and installs it to `/opt/bin/docker-compose`.

## 🚀 Quick Start

### Prerequisites

- **Flatcar Container Linux** - Immutable, container-optimized OS
- **Butane** - For converting YAML to Ignition format ([Installation guide](https://coreos.github.io/butane/getting-started/))
- **SSH access** to your Flatcar instance

### Option A: Production Deployment (Cloud)
1. **Generate configuration:** `butane --pretty --strict nextcloud-production.yaml > ignition.json`
2. **Deploy to Azure:** Use the [Azure cloud deployment guide](#azure-cloud-deployment) below
3. **Access Nextcloud:** Navigate to your server's IP address or domain

### Option B: Development Deployment (Local)
1. **Set up workspace:** Follow the [local development setup](#local-development-setup) below
2. **Start VM:** Use QEMU with the provided script and port forwarding (ports 8080, 8443)
3. **Access Nextcloud:** Open `http://localhost:8080` in your browser
   docker run --rm -p 8000:80 -d nginx
   curl localhost:8000
   ```

## 📁 Project Structure

```
flatcar-app-nextcloud/
├── README.md                      # This comprehensive guide
├── docker-compose.yml             # Multi-service container orchestration
├── nextcloud-production.yaml      # Cloud-ready Flatcar configuration
├── nextcloud-development.yaml     # Local development configuration
├── flatcar_production_qemu.sh     # Enhanced VM launcher with port forwarding
├── Makefile                       # Convenient development commands
├── .github/workflows/             # GitHub Actions CI/CD pipelines
│   └── validate-yaml.yml          # YAML validation workflow
├── .yamllint.yml                  # YAML linting configuration
├── nginx/
│   └── nextcloud.conf             # Optimized Nginx reverse proxy config
└── scripts/
    ├── backup.sh                  # Automated backup script
    ├── update.sh                  # System and container update script
    ├── validate-yaml.sh           # Comprehensive YAML validation script
    └── validate-basic.sh          # Basic validation (no external deps)
```

## 🔧 Configuration Details

### Production vs Development

| Aspect | Production | Development |
|--------|------------|-------------|
| **SSL/TLS** | Let's Encrypt automatic | Self-signed certificates |
| **Ports** | 80, 443 | 8080, 8443, 9080, 9081 |
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

### VPN and Private Access
For enhanced security, you can deploy Nextcloud behind a VPN or WireGuard:

#### Option 1: WireGuard VPN Integration
```bash
# Add WireGuard to your Flatcar configuration
# In your .yaml file, add a WireGuard service:
services:
  - name: wg-quick@wg0.service
    enabled: true
```

Configure WireGuard to:
- Only allow VPN clients to access Nextcloud ports (80/443)
- Keep database and admin ports (5432, 8081) internal-only
- Use firewall rules to block direct external access

#### Option 2: Azure Private Network
```bash
# Deploy in Azure with private networking
az network vnet create --name nextcloud-vnet --resource-group nextcloud-rg
az network subnet create --name nextcloud-subnet --vnet-name nextcloud-vnet --resource-group nextcloud-rg

# Create VM in private subnet
az vm create \
  --resource-group nextcloud-rg \
  --name nextcloud-vm \
  --subnet nextcloud-subnet \
  --public-ip-address "" \
  --custom-data ignition.json
```

#### Option 3: Cloudflare Zero Trust Tunnel
Add Cloudflare tunnel to your docker-compose.yml:
```yaml
cloudflared:
  image: cloudflare/cloudflared:latest
  command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TOKEN}
  restart: unless-stopped
  networks:
    - nextcloud-network
```

This approach:
- ✅ Hides your server's real IP address
- ✅ Provides automatic SSL/TLS termination  
- ✅ Enables access control and authentication policies
- ✅ Protects against DDoS attacks
- ✅ No need to open ports 80/443 on your firewall

### Container Security
- **Non-root execution**: All containers run as non-privileged users where possible
- **Resource limits**: Memory and CPU constraints prevent resource exhaustion
- **Health checks**: Automatic service recovery

### Data Security
- **Persistent volumes**: Data survives container restarts
- **Regular backups**: Automated backup scripts included
- **Database encryption**: PostgreSQL supports encryption at rest

## 🔄 CI/CD and Validation

This project includes comprehensive automated validation to ensure all configurations are error-free and secure.

### GitHub Actions Workflow

Every push and pull request triggers automated validation:

- **YAML Syntax Validation**: Validates all `.yaml` and `.yml` files for syntax errors
- **Docker Compose Validation**: Ensures docker-compose.yml is valid and can be parsed
- **Flatcar Configuration Validation**: Uses Butane to validate Flatcar YAML configurations
- **Style Linting**: Enforces consistent YAML formatting and style
- **Security Scanning**: Scans configurations for potential security issues
- **Ignition Generation**: Generates and validates Ignition files as artifacts

### Local Validation

Before pushing changes, run local validation:

```bash
# Quick and easy validation with Makefile
make validate              # Basic validation (minimal dependencies)
make validate-full         # Comprehensive validation (all tools required)
make docker-validate       # Docker Compose only

# Or run scripts directly:
./scripts/validate-basic.sh       # Basic validation (minimal dependencies)
./scripts/validate-yaml.sh        # Comprehensive validation (all tools required)

# Individual validations:
yamllint -c .yamllint.yml *.yaml *.yml                           # YAML linting
butane --pretty --strict nextcloud-production.yaml > /dev/null   # Flatcar validation
docker-compose config --quiet                                    # Docker Compose validation
```

### Required Tools for Development

```bash
# Install yamllint for YAML validation
pip install yamllint

# Install Butane for Flatcar validation
# See: https://coreos.github.io/butane/getting-started/

# Ensure Docker Compose is available
docker-compose version
```

### Validation Configuration

- **`.yamllint.yml`**: Defines YAML linting rules (120 char lines, 2-space indents)
- **GitHub Actions**: Automated workflows in `.github/workflows/validate-yaml.yml`
- **Local Script**: `scripts/validate-yaml.sh` for pre-commit validation


## � Deployment Guide

### Azure Cloud Deployment

#### Step 1: Prepare Your Environment
```bash
# Install required tools
# - Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
# - Butane: https://coreos.github.io/butane/getting-started/

# Authenticate with Azure
az login

# Clone this repository
git clone https://github.com/your-username/flatcar-app-nextcloud.git
cd flatcar-app-nextcloud
```

#### Step 2: Generate Ignition Configuration
```bash
# Validate and convert the production configuration
butane --pretty --strict nextcloud-production.yaml > ignition.json

# Verify the output is valid JSON
jq . ignition.json > /dev/null && echo "✅ Ignition file is valid"
```

#### Step 3: Deploy Azure Resources
```bash
# Create resource group
az group create --name nextcloud-rg --location eastus

# Create VM with Flatcar and custom data
az vm create \
  --resource-group nextcloud-rg \
  --name nextcloud-vm \
  --image flatcar-stable \
  --size Standard_B2s \
  --custom-data ignition.json \
  --admin-username core \
  --generate-ssh-keys

# Get the public IP address
VM_IP=$(az vm show -d -g nextcloud-rg -n nextcloud-vm --query publicIps -o tsv)
echo "Your Nextcloud server IP: $VM_IP"
```

#### Step 4: Verify Deployment
```bash
# SSH to your instance (may take 2-3 minutes for services to start)
ssh core@$VM_IP

# Inside the VM, check service status
docker ps
docker-compose -f /opt/nextcloud/docker-compose.yml ps

# Exit SSH and test web access
exit
curl -I http://$VM_IP
```

### Local Development Setup

#### Step 1: Set Up Flatcar Workspace
```bash
# Create and enter the workspace (following Flatcar tutorials)
mkdir flatcar
cd flatcar

# Download Flatcar QEMU tools and image
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img

# Create a backup for fresh restarts
cp flatcar_production_qemu_image.img flatcar_production_qemu_image.img.fresh

# Make the script executable
chmod +x flatcar_production_qemu.sh
```

#### Step 2: Get Nextcloud Configuration
```bash
# Clone this repository
git clone https://github.com/your-username/flatcar-app-nextcloud.git
cd flatcar-app-nextcloud

# Generate development Ignition config
butane --pretty --strict nextcloud-development.yaml > dev-ignition.json

# Verify the configuration
jq . dev-ignition.json > /dev/null && echo "✅ Development config is valid"
```

#### Step 3: Start Development VM
```bash
# Ensure fresh image (important for consistent testing)
cp ../flatcar_production_qemu_image.img.fresh ../flatcar_production_qemu_image.img

# Launch VM with Nextcloud configuration and port forwarding
# Note: Using non-privileged ports to avoid requiring sudo
../flatcar_production_qemu.sh \
  -M 4096 \
  -f 8080:80 \
  -f 8443:443 \
  -f 9080:8080 \
  -f 9081:8081 \
  -i dev-ignition.json \
  -- -snapshot

# The VM will start with these accessible endpoints:
# - Nextcloud (HTTP): http://localhost:8080
# - Nextcloud (HTTPS): https://localhost:8443 (self-signed cert)
# - Nextcloud (Direct): http://localhost:9080
# - Database Admin: http://localhost:9081
# - SSH: ssh -p 2222 core@localhost
```

#### Step 4: Verify Local Deployment
```bash
# In a new terminal, test basic Docker functionality (Flatcar tutorial style)
ssh -p 2222 core@localhost

# Run basic container test
docker run --rm -p 8000:80 -d nginx
curl localhost:8000
docker stop $(docker ps -q --filter ancestor=nginx)

# Check Nextcloud services
docker-compose -f /opt/nextcloud/docker-compose.yml ps
docker-compose -f /opt/nextcloud/docker-compose.yml logs --tail=20

# Exit SSH
exit

# Test from host machine
curl -I http://localhost:8080
curl -k -I https://localhost:8443
```

#### Step 5: Access Nextcloud Web Interface
Open your browser and navigate to:
- **Main interface:** http://localhost:8080 or https://localhost:8443
- **Direct access:** http://localhost:9080
- **Database management:** http://localhost:9081

**Default credentials:**
- **Admin user:** admin
- **Admin password:** admin123
- **Database credentials:** Available in Adminer at port 8081

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

#### Docker Compose Not Available
If you see "command not found" errors for `docker-compose`:

```bash
# Check if Docker Compose download completed
sudo systemctl status docker-compose-setup.service

# Check if binary is in place
ls -la /opt/bin/docker-compose

# Check if /opt/bin is in PATH
echo $PATH

# Manually test Docker Compose
/opt/bin/docker-compose --version
```

The system automatically downloads Docker Compose binary during first boot. If the download fails, check network connectivity and retry the service.

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
1. **Fork and clone** the repository
2. **Run local validation** before making changes: `./scripts/validate-yaml.sh`
3. **Test changes** in development environment first
4. **Validate configurations** with Butane: `butane --strict your-config.yaml`
5. **Document architectural decisions** in code comments
6. **Update README** with any new features or changes
7. **Submit pull request** - CI will automatically validate your changes

### CI/CD Pipeline
All contributions are automatically validated through GitHub Actions:
- ✅ YAML syntax and style validation
- ✅ Docker Compose configuration validation  
- ✅ Flatcar configuration validation with Butane
- ✅ Security scanning with Trivy
- ✅ Ignition file generation and testing

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
