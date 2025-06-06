# Nextcloud Production - Simplified

A streamlined, production-ready Nextcloud deployment with Collabora Online, using Docker Compose and Traefik for automatic SSL certificates.

## Features

- **Nextcloud** with PostgreSQL database
- **Collabora Online** for document editing
- **Traefik** reverse proxy with automatic Let's Encrypt SSL
- **Redis** for caching and session storage
- **Automated backup** and maintenance scripts
- **Single-command deployment** via Flatcar Linux Ignition

## Quick Start

### 1. Prepare Ignition File

```bash
# Edit SSH key in nextcloud-production.yaml
sed -i 's/YOUR_SSH_PUBLIC_KEY_HERE/your-actual-ssh-key/' nextcloud-production.yaml

# Convert to Ignition format
butane --pretty --strict nextcloud-production.yaml > prod.ign
```

### 2. Deploy to Server

Boot your Flatcar Linux server with the generated `prod.ign` file. The system will automatically:
- Install all configuration files and scripts
- Set up systemd services
- Deploy Nextcloud on first boot

**Note:** The initial deployment may take several minutes as containers are downloaded and started.

### 3. Configure Environment

After deployment, configure your environment:

```bash
# SSH to your server
ssh core@your-server-ip

# Generate secure passwords
sudo /opt/bin/generate-secrets.sh

# Edit environment (replace with your domain)
sudo nano /opt/nextcloud/.env
```

## Environment Configuration

Edit `/opt/nextcloud/.env` with your settings:

```bash
# Domain configuration
DOMAIN=nextcloud.yourdomain.com
ACME_EMAIL=admin@yourdomain.com

# Admin account
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=secure_password_here

# Database
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=secure_db_password_here
POSTGRES_DB=nextcloud

# Redis
REDIS_PASSWORD=secure_redis_password_here

# Generated automatically by generate-secrets.sh:
# NEXTCLOUD_ADMIN_PASSWORD=...
# POSTGRES_PASSWORD=...
# REDIS_PASSWORD=...
```

## Deployment

```bash
# Initial deployment (run after configuring .env)
sudo /opt/bin/deploy-production.sh

# Check container status
cd /opt/nextcloud && docker-compose ps

# View real-time logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f nextcloud-app
docker-compose logs -f nextcloud-collabora
```

## Management Scripts

All management scripts are located in `/opt/bin/`:

```bash
# System administration
sudo /opt/bin/update-system.sh         # Update system and containers
sudo /opt/bin/backup-nextcloud.sh      # Backup data and database
sudo /opt/bin/nextcloud-logs-prod.sh   # View logs with timestamps

# Nextcloud management
sudo /opt/bin/nextcloud-occ.sh status                    # Check status
sudo /opt/bin/nextcloud-occ.sh user:list                 # List users
sudo /opt/bin/nextcloud-occ.sh app:list                  # List apps
sudo /opt/bin/nextcloud-occ.sh maintenance:mode --on     # Enable maintenance

# Collabora setup (run after initial deployment)
sudo /opt/bin/nextcloud-collabora-setup.sh               # Configure Collabora integration
sudo /opt/bin/nextcloud-install-apps.sh                  # Install recommended apps
```

## Access URLs

After deployment, access your services at:

- **Nextcloud**: `https://nextcloud.yourdomain.com`
- **Collabora**: `https://collabora.yourdomain.com` 
- **Traefik Dashboard**: `https://traefik.yourdomain.com`

## File Structure

```
/opt/nextcloud/
├── docker-compose.yml          # Main container configuration
├── traefik.yml                 # Reverse proxy configuration
├── .env                        # Environment variables
├── data/                       # Nextcloud data directory
├── database/                   # PostgreSQL data
└── traefik-data/              # Traefik certificates and config
```

## Troubleshooting

### Check Service Status
```bash
cd /opt/nextcloud
docker-compose ps                    # Container status
systemctl status nextcloud.service  # Systemd service status
```

### Common Issues

**Containers not starting:**
```bash
# Check logs for errors
docker-compose logs

# Restart services
docker-compose down && docker-compose up -d
```

**SSL certificate issues:**
```bash
# Check Traefik logs
docker-compose logs traefik

# Verify domain DNS points to server
nslookup yourdomain.com
```

**Database connection errors:**
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Verify database credentials in .env file
```

## Security Notes

- All external traffic uses HTTPS with Let's Encrypt certificates
- Internal container communication uses HTTP (SSL termination at Traefik)
- Database and Redis are password-protected
- Traefik dashboard requires authentication (configure in traefik.yml)

## Backup & Maintenance

**Automated Backup:**
```bash
# Manual backup
sudo /opt/bin/backup-nextcloud.sh

# Scheduled backups (add to crontab)
0 2 * * * /opt/bin/backup-nextcloud.sh
```

**Updates:**
```bash
# Update system and containers
sudo /opt/bin/update-system.sh

# Update Nextcloud via web interface or:
sudo /opt/bin/nextcloud-occ.sh upgrade
```

## Customization

### Adding Custom Apps
```bash
# Install via web interface or OCC
sudo /opt/bin/nextcloud-occ.sh app:install app_name
sudo /opt/bin/nextcloud-occ.sh app:enable app_name
```

### Custom Configuration
- Edit `docker-compose.yml` for container settings
- Edit `traefik.yml` for reverse proxy settings  
- Use `/opt/bin/nextcloud-occ.sh config:*` commands for Nextcloud settings

## Support

For issues specific to this deployment, check:
1. Container logs: `docker-compose logs`
2. System logs: `journalctl -u nextcloud.service`
3. Nextcloud logs: `/opt/nextcloud/data/nextcloud.log`
