#!/bin/bash
# Script to install essential Nextcloud apps after initial setup

echo "Installing essential Nextcloud apps..."

cd /opt/nextcloud

# Wait for Nextcloud to be fully initialized
echo "Waiting for Nextcloud to initialize..."
attempt=0
max_attempts=30

until /opt/bin/docker-compose exec -T -u www-data nextcloud php occ status | grep -q "installed: true" || [ $attempt -ge $max_attempts ]
do
echo "Waiting for Nextcloud initialization... ($((attempt+1))/$max_attempts)"
sleep 10
attempt=$((attempt+1))
done

if [ $attempt -ge $max_attempts ]; then
echo "Nextcloud initialization timed out. Please check logs."
exit 1
fi

echo "Nextcloud initialized. Installing apps..."

# Core Productivity & Collaboration apps
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install spreed || true  # Nextcloud Talk
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install mail || true    # Nextcloud Mail
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install calendar || true # Calendar
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install richdocuments || true # Nextcloud Office
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install deck || true    # Kanban boards

# Security & Access Management
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install passwords || true # Password manager
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install twofactor_totp || true # 2FA
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install files_accesscontrol || true # File access control

# Workflow Automation & Data Management
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install flow_notifications || true # Nextcloud Flow
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install tables || true # Tables

# Knowledge & Content Management
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install collectives || true # Wiki-like app
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install notes || true # Simple notes
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install news || true # RSS reader

# Media & Design Tools
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install photos || true # Photo management
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install music || true # Music player
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install unsplash || true # Stock photos

echo "App installation completed! Log in to Nextcloud to start using these apps."

# Set some recommended app configurations
echo "Configuring apps with recommended settings..."

# Configure Collabora Online integration for document editing
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments wopi_url --value="http://collabora:9980"
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments public_wopi_url --value="http://localhost:9980"
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments disable_certificate_verification --value="yes"

# Additional Collabora settings for better compatibility
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments use_groups --value=""
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments doc_format --value="ooxml"

# Make sure the richdocuments app is enabled
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:enable richdocuments

# Ensure Nextcloud recognizes office file formats
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ maintenance:mimetype:update-db
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ maintenance:repair

# Optimize default app settings
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:system:set default_phone_region --value="US"
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:system:set memcache.local --value="\OC\Memcache\Redis"
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:system:set memcache.locking --value="\OC\Memcache\Redis"

# Allow a bit more time for services to fully initialize
echo "Waiting for services to stabilize..."
sleep 30

# Run the Collabora check script for additional configuration
echo "Running Collabora check script for additional configuration..."
/opt/bin/check-collabora.sh

echo "All done! Your Nextcloud instance is ready with pre-installed apps."
