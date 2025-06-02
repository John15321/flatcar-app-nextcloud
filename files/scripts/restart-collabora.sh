#!/bin/bash
# Script to restart Collabora and reconfigure Nextcloud integration

echo "Restarting Collabora and fixing Nextcloud integration..."

cd /opt/nextcloud

# Stop and remove Collabora container
/opt/bin/docker-compose stop collabora
/opt/bin/docker-compose rm -f collabora

# Start a fresh instance
/opt/bin/docker-compose up -d collabora

# Wait for Collabora to start
echo "Waiting for Collabora to start..."
sleep 10

# Reconfigure Nextcloud
echo "Reconfiguring Nextcloud Office app..."
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:enable richdocuments
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments wopi_url --value="http://collabora:9980"
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments public_wopi_url --value="http://localhost:9980"
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments disable_certificate_verification --value="yes"
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments use_groups --value=""

echo "Restarting Nextcloud web server..."
/opt/bin/docker-compose exec nextcloud bash -c "kill -USR1 1" 

echo "Done! Please try opening an office document now."