# Nextcloud on Flatcar Linux

This repository contains a complete Nextcloud setup for Flatcar Linux using Docker Compose.

## Features

- **Nextcloud**: Latest official image with PostgreSQL backend
- **PostgreSQL**: Reliable database with persistence
- **Redis**: Caching and session storage
- **Nginx**: Reverse proxy with SSL termination
- **Automated backups**: Daily database and data backups
- **Health checks**: Container health monitoring
- **Security**: SSL/TLS, security headers, and hardened configuration

## Quick Start

1. **Prepare SSL certificates**: Place your SSL certificate files in the `ssl/` directory:
   - `cert.pem` - SSL certificate
   - `key.pem` - Private key

2. **Configure environment**: Edit `.env` file with your settings:
   ```bash
   # Required changes
   POSTGRES_PASSWORD=your-secure-database-password
   NEXTCLOUD_ADMIN_PASSWORD=your-secure-admin-password
   NEXTCLOUD_DOMAIN=your-domain.com
   NEXTCLOUD_TRUSTED_DOMAINS=your-domain.com,localhost
   ```

3. **Deploy to Flatcar**: Use the ignition configuration to provision your Flatcar instance

4. **Access Nextcloud**: Visit `https://your-domain.com` and log in with your admin credentials

## Directory Structure

```
/opt/nextcloud/
├── docker-compose.yml    # Service definitions
├── .env                  # Environment configuration
├── data/                 # Nextcloud data files
├── config/               # Nextcloud configuration
├── apps/                 # Custom Nextcloud apps
├── db/                   # PostgreSQL data
├── redis/                # Redis data
├── ssl/                  # SSL certificates
├── nginx/                # Nginx configuration
├── backups/              # Backup storage
└── scripts/              # Maintenance scripts
```

## Management Commands

```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f nextcloud

# Restart services
systemctl restart nextcloud

# Run Nextcloud CLI commands
docker-compose exec nextcloud php occ <command>

# Manual backup
./scripts/backup.sh

# Update containers
./scripts/update.sh
```

## Backup Strategy

- **Automatic**: Daily backups via cron (database + data)
- **Retention**: 7 days (configurable)
- **Location**: `/opt/nextcloud/backups/`

## Security Considerations

- Change default passwords in `.env`
- Use strong SSL certificates
- Regular updates via update script
- Monitor logs for suspicious activity
- Consider using fail2ban for brute force protection

## Troubleshooting

1. **Container won't start**: Check logs with `docker-compose logs <service>`
2. **Permission issues**: Ensure proper ownership of data directories
3. **SSL issues**: Verify certificate files and paths
4. **Database connection**: Check PostgreSQL container status and credentials

## Customization

- **Resource limits**: Add limits to docker-compose.yml services
- **Additional apps**: Mount custom apps directory
- **Monitoring**: Add monitoring containers (Prometheus, Grafana)
- **Backup destinations**: Modify backup script for remote storage
