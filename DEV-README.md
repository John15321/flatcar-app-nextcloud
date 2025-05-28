# Nextcloud Development Setup - Flatcar QEMU

This is a **development version** of the Nextcloud setup designed for local testing with QEMU/KVM.

## Quick Start Guide

### 1. Prerequisites
- QEMU/KVM installed
- Flatcar Linux QEMU image downloaded
- SSH key pair generated

### 2. Setup SSH Key
```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Get your public key
cat ~/.ssh/id_rsa.pub

# Copy the output and paste it into dev-ignition.yaml
# Replace: "ssh-rsa AAAAB3NzaC1yc2E... your-ssh-key-here"
```

### 3. Download Flatcar Image (if needed)
```bash
# Download and extract Flatcar image
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
bunzip2 flatcar_production_qemu_image.img.bz2
```

### 4. Generate SSL Certificate (Optional - for HTTPS testing)
```bash
# Generate self-signed certificate for local development
./scripts/generate-dev-ssl.sh
```

### 5. Start the VM
```bash
# Start Flatcar VM with development configuration
./flatcar_production_qemu.sh -i dev-ignition.yaml -M 4096 -f 8080:8080 -f 8081:8081
```

### 6. Access Your Services

After 2-3 minutes (for Docker images to download), access:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Nextcloud (Direct)** | http://localhost:8080 | admin / admin123 |
| **Nextcloud (HTTP)** | http://localhost | admin / admin123 |
| **Nextcloud (HTTPS)** | https://localhost | admin / admin123 |
| **Database Admin** | http://localhost:8081 | Server: db, User: nextcloud, Pass: development_password |
| **SSH to VM** | `ssh -p 2222 core@localhost` | SSH key authentication |

## Development Features

### Port Forwarding
- **80/443**: Nginx reverse proxy (HTTP/HTTPS)
- **8080**: Direct Nextcloud access (bypass proxy)
- **8081**: Adminer database administration
- **5432**: PostgreSQL database (for external tools)
- **6379**: Redis cache (for external tools)
- **2222**: SSH access to VM

### Development Tools Included
- **Adminer**: Web-based database administration interface
- **Helper scripts**: Located in `/opt/nextcloud/scripts/` inside VM
- **Exposed ports**: All database ports available for external tools
- **Simple credentials**: Easy-to-remember passwords for testing

### VM Directory Structure
```
/opt/nextcloud/              # Main application directory
├── docker-compose.yml       # Service definitions
├── nginx.conf              # Nginx configuration
├── data/                   # Nextcloud user files
├── config/                 # Nextcloud configuration
├── apps/                   # Custom Nextcloud apps
├── db/                     # PostgreSQL database files
├── redis/                  # Redis cache files
├── ssl/                    # SSL certificates
└── scripts/                # Helper scripts
    ├── generate-ssl.sh     # SSL certificate generator
    ├── logs.sh            # View container logs
    ├── shell.sh           # Access container shell
    └── occ.sh             # Run Nextcloud CLI commands
```

## Development Workflow

### Option 1: Using VM Helper Scripts
```bash
# SSH into the VM
ssh -p 2222 core@localhost

# Change to nextcloud directory
cd /opt/nextcloud

# Use helper script for common tasks
./scripts/dev-helper.sh logs nextcloud
./scripts/dev-helper.sh shell
./scripts/dev-helper.sh occ user:list
./scripts/dev-helper.sh restart
```

### Option 2: Direct Docker Commands
```bash
# SSH into VM
ssh -p 2222 core@localhost
cd /opt/nextcloud

# View service status
docker-compose ps

# View logs
docker-compose logs -f nextcloud
docker-compose logs -f nginx

# Restart services
docker-compose down && docker-compose up -d

# Access Nextcloud shell
docker-compose exec nextcloud bash

# Run Nextcloud OCC commands
docker-compose exec -u www-data nextcloud php occ status
docker-compose exec -u www-data nextcloud php occ user:list
```

## Configuration Files

### For Development
- `dev-ignition.yaml` - Flatcar ignition configuration for QEMU
- `.env` - Development environment variables (simple passwords)
- `docker-compose.yml` - Service definitions with exposed ports
- `nginx/nextcloud.conf` - Simplified nginx configuration

### Default Credentials
- **Nextcloud Admin**: `admin` / `admin123`
- **PostgreSQL**: `nextcloud` / `development_password`
- **Redis**: No password required

## Customization

### Change Passwords
Edit `.env` file:
```bash
NEXTCLOUD_ADMIN_PASSWORD=your-new-password
POSTGRES_PASSWORD=your-new-db-password
```

### Add Trusted Domains
Edit `.env` file:
```bash
NEXTCLOUD_TRUSTED_DOMAINS=localhost,127.0.0.1,10.0.2.15,your-domain.com
```

### Enable HTTPS
1. Generate SSL certificate: `./scripts/generate-dev-ssl.sh`
2. Access via: `https://localhost` (accept browser warning)

## Troubleshooting

### VM Won't Start
```bash
# Check if image exists
ls -la flatcar_production_qemu_image.img

# Try with more memory
./flatcar_production_qemu.sh -i dev-ignition.yaml -M 8192

# Check ignition syntax
butane --strict --pretty dev-ignition.yaml
```

### Services Won't Start
```bash
# SSH into VM and check systemd
ssh -p 2222 core@localhost
sudo systemctl status nextcloud-dev
sudo journalctl -u nextcloud-dev -f

# Check Docker services
cd /opt/nextcloud
docker-compose ps
docker-compose logs
```

### Cannot Access Nextcloud
1. **Check if VM is running**: VM window should be active
2. **Wait for startup**: Initial Docker pulls take 2-3 minutes
3. **Check port forwarding**: Ensure ports aren't blocked by firewall
4. **Try different URLs**:
   - http://localhost:8080 (direct access)
   - http://localhost (via nginx)
   - https://localhost (via nginx with SSL)

### Database Connection Issues
```bash
# SSH into VM and check database
ssh -p 2222 core@localhost
cd /opt/nextcloud
docker-compose exec db psql -U nextcloud -d nextcloud -c "\l"
```

## Moving to Production

When ready for production deployment:

1. **Use production ignition.yaml** instead of dev-ignition.yaml
2. **Change all passwords** in .env file
3. **Get real SSL certificates** (Let's Encrypt or purchased)
4. **Remove development tools** (adminer, exposed ports)
5. **Configure backups** and monitoring
6. **Deploy to actual server** instead of local VM

## Network Details

### QEMU Network Setup
- VM gets IP: `10.0.2.15` (QEMU default)
- Host can access VM via forwarded ports
- VM can access internet for Docker pulls

### Port Forwarding
```bash
# Forwarded in flatcar_production_qemu.sh script
-f 8080:8080    # Direct Nextcloud access
-f 8081:8081    # Adminer database admin
# Default SSH: -f 2222:22 (usually automatic)
```

This development setup gives you a complete Nextcloud environment for testing, development, and learning how the components work together!
