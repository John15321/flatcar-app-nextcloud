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

## Future: Production Collabora Setup

When ready to enable full Collabora functionality, the following will be needed:

### Production Requirements
- **SSL/TLS certificates** - Proper HTTPS setup
- **Domain name** - Real domain instead of localhost
- **Reverse proxy** - Nginx or Traefik for proper routing
- **Security headers** - HSTS, CSP, and frame-ancestors
- **Network isolation** - Proper container networking

### Planned Production Features
- Full document editing (Word, Excel, PowerPoint)
- Real-time collaborative editing
- Version history and conflict resolution
- Mobile app support
- Advanced security policies

### Migration Path
The current setup provides the foundation:
- All apps and infrastructure are pre-installed
- WOPI configuration framework is in place
- Troubleshooting tools are available
- Easy transition to production deployment

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

This setup provides a complete, production-like Nextcloud environment with essential apps pre-configured for immediate productivity and development work.
