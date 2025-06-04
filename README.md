# Simplified Nextcloud Development Setup

This is a streamlined Nextcloud development environment for Flatcar Container Linux, designed for quick setup and testing.

## Features

- **Direct Nextcloud access** - No reverse proxy complexity
- **Simple authentication** - admin/admin123 for easy testing
- **Core services only** - Nextcloud, PostgreSQL, Redis, Adminer
- **Essential scripts** - Basic utility scripts for management
- **Optional Collabora** - Separate compose file for office functionality

## Quick Start

1. **Replace SSH key** in `nextcloud-development.yaml` with your public key
2. **Generate Ignition config:**
   ```bash
   butane --pretty --strict nextcloud-development.yaml > dev.ign
   ```
3. **Launch VM:**
   ```bash
   ./flatcar_production_qemu.sh -i dev.ign -M 4096 -f 8080:8080 -f 8081:8081
   ```
4. **Access services:**
   - Nextcloud: http://localhost:8080 (admin/admin123)
   - Adminer: http://localhost:8081

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Nextcloud | 8080 | Main application |
| Adminer | 8081 | Database management |
| PostgreSQL | 5432 | Database (exposed for dev tools) |
| Redis | 6379 | Cache (exposed for dev tools) |

## Available Scripts

| Script | Purpose |
|--------|---------|
| `nextcloud-logs.sh` | View container logs |
| `nextcloud-shell.sh` | Access Nextcloud container shell |
| `nextcloud-occ.sh` | Run Nextcloud CLI commands |
| `nextcloud-reset.sh` | Reset the entire environment |

## Optional: Add Collabora Office

To enable document editing capabilities:

```bash
# SSH into the VM
ssh -p 2222 core@localhost

# Add Collabora service
cd /opt/nextcloud
/opt/bin/docker-compose -f docker-compose.yml -f docker-compose.collabora.yml up -d
```

Access Collabora at: http://localhost:9980

## Differences from Original Setup

**Removed:**
- Nginx reverse proxy (complexity)
- SSL certificate generation (unnecessary for dev)
- Automatic app installation (too many apps)
- Collabora health monitoring (overkill)
- Development info/logging services (not essential)

**Simplified:**
- Direct Nextcloud access on port 8080
- Minimal systemd services
- Essential utility scripts only
- Optional Collabora as separate addon

## File Structure

```
files/
├── configs/
│   ├── docker-compose.yml          # Main services
│   ├── docker-compose.collabora.yml # Optional Collabora
│   └── .env                        # Environment variables
├── scripts/                        # Essential utility scripts
└── services/                       # Minimal systemd services
```

## Development Workflow

1. **Start developing:** VM boots automatically with Nextcloud running
2. **View logs:** `nextcloud-logs.sh`
3. **Execute commands:** `nextcloud-occ.sh`
4. **Access shell:** `nextcloud-shell.sh`
5. **Database access:** Visit http://localhost:8081 (Adminer)
6. **Reset environment:** `nextcloud-reset.sh` (if needed)

This simplified setup focuses on core Nextcloud functionality while maintaining ease of development and debugging.
