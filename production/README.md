# Production README for Nextcloud

This directory contains the complete production-ready configuration for deploying Nextcloud with enterprise-grade security and scalability.

## Quick Start Options

### Option 1: Azure Deployment (Recommended)

```bash
# 1. Configure variables
cd production/azure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# 2. Deploy infrastructure (choose one)
# Using Terraform:
terraform init
terraform plan
terraform apply

# Or using OpenTofu:
tofu init
tofu plan
tofu apply

# 3. Access your Nextcloud
# URLs will be displayed in the outputs
```

### Option 2: Standalone Server

```bash
# 1. Replace SSH key in production/nextcloud-production.yaml
# 2. Generate production configuration
cd production
butane --pretty --strict nextcloud-production.yaml > prod.ign

# 3. Deploy to your server
# Boot Flatcar with the generated prod.ign file

# 4. SSH to server and complete setup
ssh core@YOUR_SERVER_IP

# Option A: Interactive deployment (recommended)
sudo /opt/bin/deploy-production.sh

# Option B: Manual deployment
sudo /opt/bin/generate-secrets.sh
sudo /opt/bin/setup-production.sh  # or --internal-https
sudo systemctl start nextcloud-production

# 5. Access Nextcloud at https://your-domain.com
```

## Key Features

### 🔒 Security Hardened
- **Traefik reverse proxy** with automatic SSL/TLS (Let's Encrypt)
- **Strong password generation** and secure credential management
- **Security headers** (HSTS, CSP, X-Frame-Options, etc.)
- **Network isolation** between services
- **Fail2ban** for brute force protection
- **Firewall rules** and port restrictions

### 🚀 Production Ready
- **Automatic SSL certificates** via Let's Encrypt
- **Health checks** and monitoring
- **Automated backups** with retention policies
- **System updates** via Watchtower
- **Log aggregation** and rotation
- **Resource optimization** for production workloads

### 📱 Full Collabora Integration
- **Complete document editing** (Word, Excel, PowerPoint)
- **Real-time collaboration** with multiple users
- **Proper SSL/WOPI configuration** for secure communication
- **Mobile app support** with full editing capabilities

### 🌐 Deployment Flexibility
- **Azure deployment** with Terraform/OpenTofu ([see OpenTofu guide](OPENTOFU.md))
- **Standalone server** deployment
- **Domain or IP-based** configuration
- **Scalable architecture** ready for growth

## 🔧 How It Works

### SSL/HTTPS Architecture

**Question: How do backend services enable HTTPS without being in a domain?**

This production setup uses **SSL termination at the reverse proxy** level:

```
Internet → Traefik (HTTPS/SSL) → Backend Services (HTTP internally)
```

**1. External HTTPS (Public)**
- **Traefik** handles all SSL/TLS termination on ports 80/443
- **Let's Encrypt** automatically provisions and renews SSL certificates
- **Domain-based**: Requires a real domain (e.g., `nextcloud.yourdomain.com`)
- **Certificate storage**: Stored in Docker volume `traefik_certs:/certs/acme.json`

**2. Internal HTTP (Secure Network)**
- Backend services (Nextcloud, DB, Redis) communicate via **HTTP internally**
- **Network isolation**: All services run on isolated Docker networks
- **No public exposure**: Only Traefik is exposed to the internet
- **Firewall protection**: NSG rules restrict access to ports 22, 80, 443 only

**3. Certificate Management**
- **Automatic**: Let's Encrypt TLS challenge handles domain verification
- **Renewal**: Certificates auto-renew every 60 days
- **Backup**: Certificate data persists in Docker volumes
- **Security**: TLS 1.2+ only, strong cipher suites configured

### Internal HTTPS (Advanced Security)

For environments requiring end-to-end encryption, this setup supports **internal HTTPS** for all container-to-container communication:

**Internal HTTPS Features:**
- **Full encryption**: All communication between containers uses TLS
- **Self-signed certificates**: Automatically generated internal CA and certificates
- **Service coverage**: Nextcloud, PostgreSQL, Redis, Traefik internal routes
- **Zero trust**: No unencrypted communication within the infrastructure

**Deployment with Internal HTTPS:**
```bash
# 1. Deploy with internal HTTPS support
sudo /opt/bin/setup-production.sh --internal-https

# 2. Start with internal HTTPS compose file
docker-compose -f docker-compose.internal-https.yml up -d

# 3. Configure Collabora with internal HTTPS
sudo /opt/bin/nextcloud-collabora-setup.sh configure
```

**When to use Internal HTTPS:**
- **High security environments** (healthcare, financial, government)
- **Compliance requirements** (HIPAA, SOX, etc.)
- **Zero-trust architecture** implementations
- **Multi-tenant environments** with strict isolation

**See**: `INTERNAL-HTTPS.md` for complete internal HTTPS setup guide.

### Backup System

**"What kind of backups do we have?"**

**1. Local File Backups**
- **Location**: `/opt/backups/` on the server
- **Content**: Database dumps, Nextcloud data, configuration files
- **Schedule**: Automated via cron (configurable)
- **Retention**: 30 days by default (configurable via `BACKUP_RETENTION_DAYS`)

**2. Backup Components**
```bash
/opt/backups/nextcloud_backup_20250606_123456/
├── database.sql.gz          # PostgreSQL database dump
├── nextcloud_data.tar.gz    # All user files, config, apps
├── env_backup               # Environment variables
└── backup_info.txt          # Backup metadata
```

**3. Azure Cloud Backups (Optional)**
- **Storage**: Azure Blob Storage container `nextcloud-backups`
- **Replication**: LRS (Locally Redundant Storage)
- **Access**: Via Azure Storage Account with secure access keys
- **Lifecycle**: Can be extended with Azure lifecycle policies

**4. Backup Process**
- **Maintenance mode**: Enables before backup to ensure consistency
- **Database**: Live PostgreSQL dump via `pg_dump`
- **Files**: Compressed tar archives of data/config/apps
- **Atomic**: All-or-nothing backup with rollback on failure

### Network Architecture

**Docker Networks:**
```
┌─────────────────┐    ┌─────────────────┐
│   Internet      │────│   Traefik       │
│                 │    │  (SSL/HTTPS)    │
└─────────────────┘    └─────────────────┘
                                │
                       ┌────────┴────────┐
                       │  traefik network │
                       │   (external)     │
                       └────────┬────────┘
                                │
                       ┌────────┴────────┐
                       │nextcloud-internal│
                       │   (isolated)     │
                       └─────────────────┘
                                │
                    ┌───────────┼───────────┐
                    │           │           │
              ┌──────────┐ ┌─────────┐ ┌─────────┐
              │Nextcloud │ │PostgreSQL│ │  Redis  │
              │   App    │ │    DB    │ │  Cache  │
              └──────────┘ └─────────┘ └─────────┘
```

**Security Layers:**
- **External**: Only ports 22 (SSH), 80 (HTTP→HTTPS redirect), 443 (HTTPS)
- **Network**: Internal Docker network isolates backend services
- **Container**: Each service runs in isolated containers
- **Access**: SSH key-only authentication, no password login

### Data Persistence

**Docker Volumes:**
- `nextcloud_data`: Nextcloud application files
- `postgres_data`: Database storage
- `redis_data`: Cache storage  
- `traefik_certs`: SSL certificates

**Azure Deployment:**
- **Managed Disk**: Separate Azure managed disk for data persistence
- **Size**: Configurable (default 50GB, up to 4TB)
- **Type**: Standard_LRS or Premium_SSD
- **Backup**: Azure disk snapshots + application-level backups

### Monitoring & Updates

**Automatic Updates:**
- **Watchtower**: Monitors and updates Docker images
- **Schedule**: 2 AM daily (configurable)
- **Safety**: Only updates when new versions are available
- **Rollback**: Previous images retained for emergency rollback

**Health Monitoring:**
- **Docker health checks**: Built into each service
- **Traefik dashboard**: Service health and metrics
- **Log aggregation**: Centralized logging via Docker logging drivers

## What's Different from Development

| Feature | Development | Production |
|---------|-------------|------------|
| **Access** | HTTP:8080 direct | HTTPS via Traefik |
| **SSL** | None | Automatic Let's Encrypt |
| **Passwords** | Simple (admin/admin123) | Strong generated passwords |
| **Security** | Basic | Headers, firewall, fail2ban |
| **Backups** | Manual | Automated daily |
| **Updates** | Manual | Automatic security updates |
| **Monitoring** | Basic logs | Comprehensive logging |
| **Networks** | Exposed ports | Isolated internal networks |
| **Collabora** | Limited HTTP setup | Full HTTPS integration |

## Configuration Structure

```
production/
├── configs/                        # Configuration files
│   ├── docker-compose.prod.yml     # Production container stack
│   ├── .env.example                # Environment variables template
│   └── traefik/                    # Reverse proxy configuration
│       ├── traefik.yml             # Main config: SSL, routing, API
│       └── dynamic.yml             # Security: TLS policies, headers
├── azure/                          # Azure cloud deployment
│   ├── main.tf                     # Infrastructure: VM, networking, storage
│   ├── variables.tf                # Configurable parameters
│   ├── outputs.tf                  # URLs, IPs, connection info
│   └── terraform.tfvars.example    # Azure-specific settings
├── scripts/                        # Automation and maintenance
│   ├── setup-production.sh         # Initial deployment automation
│   ├── generate-secrets.sh         # Secure password generation
│   ├── backup-nextcloud.sh         # Database + file backup system
│   ├── update-system.sh            # Security patches and updates
│   ├── nextcloud-occ.sh            # Nextcloud CLI access
│   ├── nextcloud-logs-prod.sh      # Log viewing and analysis
│   ├── nextcloud-install-apps.sh   # App installation automation
│   └── nextcloud-collabora-setup.sh# Office suite integration
├── standalone/                     # Bare metal deployment
│   └── install.sh                  # Server installation script
├── nextcloud-production.yaml       # Flatcar/Butane system config
├── OPENTOFU.md                     # OpenTofu usage guide
└── README.md                       # This comprehensive guide
```

## Migration from Development

To migrate from your development environment:

1. **Export data** from development setup
2. **Deploy production** configuration
3. **Import data** using migration scripts
4. **Update DNS** to point to production
5. **Configure monitoring** and backups

## Domain vs IP Address

### With Custom Domain (Recommended)
- Automatic SSL certificates via Let's Encrypt
- Professional appearance and branding
### With Domain (Recommended)
- **Automatic SSL**: Let's Encrypt provides free, valid certificates
- **Trusted certificates**: No browser warnings, full mobile app support
- **Email functionality**: Proper email delivery and notifications
- **Collabora Online**: Full office suite functionality
- **Professional appearance**: Branded URLs like `nextcloud.yourcompany.com`

### With Public IP Only
- **Manual SSL**: Requires purchasing SSL certificates or accepting warnings
- **Self-signed certificates**: Browser security warnings, mobile app issues
- **Limited functionality**: Some apps/features require trusted SSL
- **Email limitations**: May have delivery issues due to IP-based setup

**Domain Setup Requirements:**
1. **DNS A Record**: Point your domain to the server's public IP
2. **Port 80 access**: Required for Let's Encrypt domain verification
3. **Domain ownership**: Must control DNS for the domain
4. **Firewall**: Ensure ports 80/443 are open for certificate challenges

## 📋 Configuration Details

### Environment Variables

The production setup uses these key environment variables (configured in `/opt/nextcloud/.env`):

**Core Configuration:**
```bash
DOMAIN=nextcloud.yourdomain.com     # Your Nextcloud domain
PUBLIC_IP=123.456.789.123          # Server public IP (fallback)
ACME_EMAIL=admin@yourdomain.com    # Let's Encrypt contact email
```

**Database Configuration:**
```bash
POSTGRES_DB=nextcloud              # Database name
POSTGRES_USER=nextcloud_user       # Database username
POSTGRES_PASSWORD=<generated>      # Strong generated password
```

**Application Configuration:**
```bash
NEXTCLOUD_ADMIN_USER=admin         # Nextcloud admin username
NEXTCLOUD_ADMIN_PASSWORD=<generated> # Strong admin password
REDIS_PASSWORD=<generated>         # Redis cache password
```

**Security Configuration:**
```bash
TRAEFIK_AUTH=<htpasswd>           # Traefik dashboard auth
COLLABORA_ADMIN_USER=admin        # Collabora admin user
COLLABORA_ADMIN_PASSWORD=<generated> # Collabora admin password
```

### Automated Secret Generation

The `generate-secrets.sh` script creates secure passwords:
- **32-character** alphanumeric passwords
- **Bcrypt hashed** passwords for HTTP basic auth
- **Automatic substitution** in configuration files
- **Backup** of original files before modification

### Service URLs and Access

After deployment, access these services:

**Primary Services:**
- **Nextcloud**: `https://yourdomain.com` (main application)
- **Collabora**: `https://office.yourdomain.com` (office suite)

**Administrative Services:**
- **Traefik Dashboard**: `https://traefik.yourdomain.com` (proxy admin)
  - Username: admin
  - Password: Generated during setup

## Support and Troubleshooting

All development utilities are available in production:

```bash
# SSH to your production server
ssh core@your-server-ip

# View logs
/opt/bin/nextcloud-logs-prod.sh

# Run OCC commands
/opt/bin/nextcloud-occ.sh

# Check backup status
/opt/bin/backup-nextcloud.sh status

# Update system
/opt/bin/update-system.sh
```

## Security Considerations

- **Change default SSH port** if desired
- **Restrict SSH access** to known IP addresses
- **Enable 2FA** for all admin accounts
- **Monitor logs** regularly for suspicious activity
- **Keep backups** in multiple locations
- **Test disaster recovery** procedures

## Scaling and Performance

The production setup is designed to scale:

- **Database optimization** with PostgreSQL tuning
- **Redis caching** for improved performance
- **CDN-ready** static asset serving
- **Load balancer** support via Traefik
- **Horizontal scaling** capabilities

Ready for enterprise deployment with proper security, monitoring, and backup procedures.

## OpenTofu Support

This configuration fully supports **OpenTofu** as a drop-in replacement for Terraform. See [OPENTOFU.md](OPENTOFU.md) for detailed information about using OpenTofu instead of Terraform, including installation, migration, and compatibility details.
