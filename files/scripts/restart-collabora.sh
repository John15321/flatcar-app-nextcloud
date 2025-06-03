#!/bin/bash
# Restart Collabora Online service

echo "Restarting Collabora Online..."
cd /opt/nextcloud

# Stop Collabora container
echo "Stopping Collabora container..."
/opt/bin/docker-compose stop collabora

# Remove container to ensure clean restart
echo "Removing Collabora container..."
/opt/bin/docker-compose rm -f collabora

# Start Collabora container
echo "Starting Collabora container..."
/opt/bin/docker-compose up -d collabora

# Wait for service to be ready
echo "Waiting for Collabora to start..."
sleep 10

# Check status
echo "Checking Collabora status..."
/opt/bin/check-collabora.sh