#!/bin/bash
# Script to diagnose Collabora Online integration issues

echo "==============================================="
echo "Checking Collabora Online integration with Nextcloud"
echo "==============================================="

cd /opt/nextcloud

# Check if Collabora container is running
echo "1. Checking if Collabora container is running..."
if docker ps | grep -q nextcloud-collabora; then
echo "✅ Collabora container is running"
collabora_status="running"
else
echo "❌ Collabora container is NOT running"
echo "Trying to start it..."
/opt/bin/docker-compose up -d collabora
sleep 5
if docker ps | grep -q nextcloud-collabora; then
    echo "✅ Collabora container started successfully"
    collabora_status="running"
else
    echo "❌ Failed to start Collabora container"
    docker-compose logs collabora
    collabora_status="not running"
fi
fi

# Check if richdocuments app is installed and enabled
echo
echo "2. Checking if richdocuments app is installed and enabled..."
if /opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:list | grep -q "✓ richdocuments"; then
echo "✅ Nextcloud Office (richdocuments) app is installed and enabled"
app_status="enabled"
else
echo "❌ Nextcloud Office app is not installed or not enabled"
echo "Attempting to install and enable richdocuments..."
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:install richdocuments
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ app:enable richdocuments
if docker-compose exec -T -u www-data nextcloud php occ app:list | grep -q "✓ richdocuments"; then
    echo "✅ Successfully installed and enabled richdocuments app"
    app_status="enabled"
else
    echo "❌ Failed to install or enable richdocuments app"
    app_status="disabled"
fi
fi

# Check richdocuments configuration
echo
echo "3. Checking richdocuments app configuration..."
wopi_url=$(/opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:get richdocuments wopi_url)
echo "Current WOPI URL: $wopi_url"

# Test connectivity from Nextcloud to Collabora
echo
echo "4. Testing connectivity from Nextcloud container to Collabora..."
if [ "$collabora_status" == "running" ]; then
/opt/bin/docker-compose exec nextcloud curl -s -I "$wopi_url" > /tmp/collabora_response 2>&1
if grep -q "HTTP/1.1 200" /tmp/collabora_response || grep -q "HTTP/1.1 301" /tmp/collabora_response || grep -q "HTTP/1.1 302" /tmp/collabora_response; then
    echo "✅ Nextcloud can connect to Collabora"
else
    echo "❌ Nextcloud cannot connect to Collabora"
    cat /tmp/collabora_response
    
    echo
    echo "5. Fixing WOPI URL configuration..."
    echo "Setting wopi_url to http://collabora:9980..."
    /opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments wopi_url --value="http://collabora:9980"
    
    echo "Setting public_wopi_url to https://localhost:9980..."
    /opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments public_wopi_url --value="https://localhost:9980"
    
    echo "Disabling certificate verification..."
    /opt/bin/docker-compose exec -T -u www-data nextcloud php occ config:app:set richdocuments disable_certificate_verification --value="yes"
fi
fi

# Check Collabora logs
echo
echo "6. Checking Collabora container logs for errors..."
/opt/bin/docker-compose logs --tail=50 collabora | grep -i "error"

# Check if Collabora is working from inside the container
echo
echo "7. Testing Collabora service from inside the container..."
/opt/bin/docker-compose exec collabora curl -s http://localhost:9980/ | grep -q "OK" && echo "✅ Collabora is working inside the container" || echo "❌ Collabora is not responding correctly inside its container"

# Fix the permissions and restart
echo
echo "8. Applying fixes and restarting services..."
/opt/bin/docker-compose exec -T -u www-data nextcloud php occ maintenance:repair

# Restart Collabora and Nextcloud
echo
echo "9. Restarting services..."
/opt/bin/docker-compose restart collabora nextcloud

echo
echo "10. Diagnostics complete. Please try opening office documents again."
echo "If issues persist, check detailed logs with: docker-compose logs collabora"
echo "==============================================="