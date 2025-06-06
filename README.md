# Nextcloud Development Setup with Essential Apps

This is a complete Nextcloud development environment for Flatcar Container Linux, designed for productivity and development with essential apps pre-installed.

## Features

- **Direct Nextcloud access** - No reverse proxy complexity
- **Simple authentication** - admin/admin123 for easy testing
- **Essential services** - Nextcloud, PostgreSQL, Redis, Adminer
- **Automatic app installation** - Essential productivity and development apps
- **Collabora Online included** - Document editing infrastructure (requires production setup)
- **Development utilities** - Comprehensive scripts for management

## Quick Start

1. **Replace SSH key** in `nextcloud-development.yaml` with your public key
2. **Generate Ignition config:**
   ```bash
   make ignition-dev
   # or manually: butane --pretty --strict nextcloud-development.yaml > dev.ign
   ```
3. **Launch VM:**
   ```bash
   make run-dev
   # or manually: ./flatcar_production_qemu.sh -i dev.ign -M 4096 -f 8080:8080 -f 8081:8081 -f 9980:9980
   ```
4. **Access services:**
   - Nextcloud: http://localhost:8080 (admin/admin123)
   - Adminer: http://localhost:8081
   - Collabora: http://localhost:9980 (infrastructure ready)

## Services

| Service | Port | Purpose | Status |
|---------|------|---------|--------|
| Nextcloud | 8080 | Main application | ✅ Ready |
| Adminer | 8081 | Database management | ✅ Ready |
| Collabora | 9980 | Document editing | ⚠️ Needs production config |
| PostgreSQL | 5432 | Database (exposed for dev tools) | ✅ Ready |
| Redis | 6379 | Cache (exposed for dev tools) | ✅ Ready |

## Pre-installed Apps

The setup automatically installs these essential apps:

**Office & Productivity:**
- Collabora Online (richdocuments app - infrastructure ready)
- Deck (Kanban Board)
- Notes, Calendar, Contacts, Mail, Tasks

**Development & Admin:**
- External Storage Support
- LDAP Integration
- Two-Factor Authentication (TOTP)
- Admin Audit Logging
- File Access Control
- Brute Force Protection
- Suspicious Login Detection

**File Management:**
- Download Activity Tracking
- File Retention
- Group Folders

## Available Scripts

| Script | Purpose |
|--------|---------|
| `nextcloud-logs.sh` | View container logs |
| `nextcloud-shell.sh` | Access Nextcloud container shell |
| `nextcloud-occ.sh` | Run Nextcloud CLI commands |
| `nextcloud-reset.sh` | Reset the entire environment |
| `nextcloud-install-apps.sh` | Install additional apps manually |
| `nextcloud-collabora-setup.sh` | Configure/troubleshoot Collabora |

## Collabora Online Status

**Current State:** Infrastructure Ready - Requires Production Configuration

The setup includes:
- ✅ Collabora Online container configured
- ✅ richdocuments app installed and enabled
- ✅ Basic WOPI configuration applied
- ⚠️ Local HTTP setup has known limitations

**For Development Use:**
- All office document apps functionality is available except live editing
- Documents can be uploaded, downloaded, and managed
- Collabora infrastructure is ready for production deployment

**Known Limitation:**
Local HTTP Collabora setups have inherent security and connectivity challenges. For reliable document editing, a production configuration with proper SSL/TLS and domain setup is recommended.

**Troubleshooting Tools Available:**
```bash
ssh -p 2222 core@localhost

# Run comprehensive diagnostics
/opt/bin/nextcloud-debug-collabora.sh

# Try automated fixes
/opt/bin/nextcloud-fix-collabora.sh

# Manual configuration
/opt/bin/nextcloud-collabora-setup.sh configure

# Check current status
/opt/bin/nextcloud-collabora-setup.sh status
```

**Verification Commands:**
```bash
# Check containers are running
docker ps | grep -E "(nextcloud|collabora)"

# Test Collabora discovery endpoint
curl http://localhost:9980/hosting/discovery

# Check richdocuments app status
/opt/bin/nextcloud-occ.sh app:list | grep richdocuments
```

## App Management

**View installed apps:**
```bash
ssh -p 2222 core@localhost
/opt/bin/nextcloud-occ.sh app:list
```

**Install additional apps:**
```bash
/opt/bin/nextcloud-occ.sh app:install app_name
/opt/bin/nextcloud-occ.sh app:enable app_name
```

**Or use the automated script:**
```bash
/opt/bin/nextcloud-install-apps.sh
```

## What's New in This Setup

**Added:**
- Automatic installation of essential Nextcloud apps
- Integrated Collabora Online for document editing
- Comprehensive productivity app suite
- Enhanced security apps (2FA, brute force protection)
- Development-friendly apps (external storage, LDAP)

**Simplified from Original:**
- Removed Nginx reverse proxy (complexity)
- Removed SSL certificate generation (unnecessary for dev)
- Removed health monitoring (overkill for development)

**Architecture:**
- Direct Nextcloud access on port 8080
- Collabora integrated on port 9980
- Essential apps installed automatically
- Simple admin/admin123 authentication

## File Structure

```
files/
├── configs/
│   ├── docker-compose.yml          # Main services (includes Collabora)
│   ├── docker-compose.collabora.yml # Standalone Collabora (legacy)
│   └── .env                        # Environment variables
├── scripts/                        # Development and management scripts
│   ├── nextcloud-install-apps.sh   # App installation automation
│   └── ...                         # Other utility scripts
└── services/                       # Systemd services
    ├── nextcloud-install-apps.service # App installation service
    └── ...                         # Other system services
```

## Development Workflow

1. **Start developing:** VM boots automatically with Nextcloud and all apps ready
2. **Document management:** Upload, organize, and download office documents
3. **View logs:** `nextcloud-logs.sh`
4. **Execute commands:** `nextcloud-occ.sh`
5. **Access shell:** `nextcloud-shell.sh`
6. **Database access:** Visit http://localhost:8081 (Adminer)
7. **Install more apps:** `nextcloud-install-apps.sh` or via web interface
8. **Reset environment:** `nextcloud-reset.sh` (if needed)

**Note:** Collabora Online document editing requires production configuration for reliable operation.

## 🚀 Production Deployment Available

This repository includes a **complete production-ready configuration** for full Nextcloud deployment with Collabora Online.

### Production Features ✅
- **Full document editing** - Word, Excel, PowerPoint with real-time collaboration
- **Enterprise security** - SSL/TLS, security headers, firewall protection
- **Multiple deployment options** - Azure cloud or standalone servers
- **Automated SSL certificates** - Let's Encrypt integration
- **Professional infrastructure** - Traefik reverse proxy, Redis, PostgreSQL
- **Backup & monitoring** - Automated backups and comprehensive logging

### Getting Started with Production
```bash
# Option 1: Azure deployment (recommended)
cd production/azure && terraform apply

# Option 2: Standalone server
make ignition-prod
# Deploy to your server and run setup

# Option 3: Full manual control
cd production && butane nextcloud-production.yaml > prod.ign
```

📖 **Complete documentation:** See `production/README.md` for detailed deployment guides.

### Migration from Development
The production setup builds on this development environment:
- ✅ All apps and infrastructure are compatible
- ✅ Easy data migration path available  
- ✅ Same app ecosystem and functionality
- ✅ Comprehensive migration documentation

## Troubleshooting & Diagnostics

### General Troubleshooting
```bash
# Check all containers
docker ps

# View Nextcloud logs
nextcloud-logs.sh

# Access container shell
nextcloud-shell.sh

# Check app status
nextcloud-occ.sh app:list
```

### Collabora Diagnostics (Development)
```bash
# Try automated fixes in order of increasing impact
nextcloud-fix-collabora.sh

# Or use specific fixes:
nextcloud-fix-collabora.sh restart    # Just restart Collabora
nextcloud-fix-collabora.sh recreate   # Recreate containers
nextcloud-fix-collabora.sh stable     # Use stable version
```

### Manual Diagnostics
```bash
# Run comprehensive Collabora debugging
nextcloud-debug-collabora.sh

# Check specific Collabora configuration
nextcloud-collabora-setup.sh status

# View Collabora logs
docker logs nextcloud-collabora

# Test connectivity manually
curl http://localhost:9980/hosting/discovery
```

### Common Issues and Solutions

1. **Collabora container not starting:**
   ```bash
   docker restart nextcloud-collabora
   # Or restart all containers:
   cd /opt/nextcloud && docker-compose restart
   ```

2. **WOPI connection errors:**
   ```bash
   nextcloud-collabora-setup.sh configure
   ```

3. **Documents won't open/edit:**
   - Check if richdocuments app is enabled in Nextcloud admin panel
   - Verify Collabora settings in Nextcloud Admin → Office
   - Run: `nextcloud-debug-collabora.sh` for detailed analysis

4. **Complete reset (if all else fails):**
   ```bash
   cd /opt/nextcloud
   docker-compose down -v
   docker-compose up -d
   # Wait for startup, then run:
   nextcloud-install-apps.sh
   ```

### Collabora URLs
- **Collabora Admin Panel:** http://localhost:9980 (admin/admin123)
- **Discovery Endpoint:** http://localhost:9980/hosting/discovery
- **Integration Settings:** Nextcloud Admin → Office

## 🚀 Production Deployment

This development setup provides the foundation for production deployment. A complete **production-ready configuration** is available in the `/production` directory with:

- **🔒 Security hardened** - Traefik reverse proxy, SSL/TLS, strong passwords
- **☁️ Azure deployment** - Terraform/OpenTofu automation for cloud deployment  
- **🖥️ Standalone server** - Installation scripts for any Linux server
- **📋 Domain flexibility** - Works with custom domains or public IP
- **🔧 Full automation** - Scripts for setup, backups, and maintenance

### Quick Production Start

**Option 1: Azure Deployment (Recommended)**
```bash
cd production/azure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Using Terraform:
terraform init && terraform plan && terraform apply

# Or using OpenTofu:
tofu init && tofu plan && tofu apply
```

**Option 2: Standalone Server**
```bash
make ignition-prod  # Generate production configuration
# Deploy to your server and run setup scripts
```

**📖 Complete Documentation:** See `/production/README.md` for detailed deployment instructions, security features, and migration guides.

---

This setup provides a complete, production-like Nextcloud environment with essential apps pre-configured for immediate productivity and development work.
