# Nextcloud Development Setup with Essential Apps

This is a complete Nextcloud development environment for Flatcar Container Linux, designed for productivity and development with essential apps pre-installed.

## Features

- **Direct Nextcloud access** - No reverse proxy complexity
- **Simple authentication** - admin/admin123 for easy testing
- **Essential services** - Nextcloud, PostgreSQL, Redis, Collabora, Adminer
- **Automatic app installation** - Essential productivity and development apps
- **Collabora Online integration** - Document editing out-of-the-box
- **Development utilities** - Comprehensive scripts for management

## Quick Start

1. **Replace SSH key** in `nextcloud-development.yaml` with your public key
2. **Generate Ignition config:**
   ```bash
   butane --pretty --strict nextcloud-development.yaml > dev.ign
   ```
3. **Launch VM:**
   ```bash
   ./flatcar_production_qemu.sh -i dev.ign -M 4096 -f 8080:8080 -f 8081:8081 -f 9980:9980
   ```
4. **Access services:**
   - Nextcloud: http://localhost:8080 (admin/admin123)
   - Collabora: http://localhost:9980
   - Adminer: http://localhost:8081

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Nextcloud | 8080 | Main application |
| Collabora | 9980 | Document editing |
| Adminer | 8081 | Database management |
| PostgreSQL | 5432 | Database (exposed for dev tools) |
| Redis | 6379 | Cache (exposed for dev tools) |

## Pre-installed Apps

The setup automatically installs these essential apps:

**Office & Productivity:**
- Collabora Online (Office Documents)
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

## Collabora Troubleshooting

If Collabora isn't working properly, use the dedicated troubleshooting script:

```bash
ssh -p 2222 core@localhost

# Test Collabora integration
/opt/bin/nextcloud-collabora-setup.sh test

# Reconfigure Collabora
/opt/bin/nextcloud-collabora-setup.sh configure

# Check status and configuration
/opt/bin/nextcloud-collabora-setup.sh status

# Run full troubleshooting
/opt/bin/nextcloud-collabora-setup.sh troubleshoot
```

**Common Issues:**
- **"Server error" when opening documents**: Try reconfiguring with the setup script
- **Documents won't open**: Check that both containers are running and can communicate
- **Permission errors**: Ensure the richdocuments app is enabled and properly configured

**Manual Verification:**
```bash
# Check containers are running
docker ps | grep -E "(nextcloud|collabora)"

# Test Collabora discovery endpoint
curl http://localhost:9980/hosting/discovery

# Check Nextcloud logs
/opt/bin/nextcloud-logs.sh collabora
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
2. **Document editing:** Collabora Online available immediately
3. **View logs:** `nextcloud-logs.sh`
4. **Execute commands:** `nextcloud-occ.sh`
5. **Access shell:** `nextcloud-shell.sh`
6. **Database access:** Visit http://localhost:8081 (Adminer)
7. **Install more apps:** `nextcloud-install-apps.sh` or via web interface
8. **Reset environment:** `nextcloud-reset.sh` (if needed)

## Troubleshooting Collabora

If Collabora Online is not working properly, use these debugging and fix tools:

### Quick Fix (Recommended)
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
