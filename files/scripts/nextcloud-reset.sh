#!/bin/bash
# Reset Nextcloud for development (WARNING: Destroys all data!)

echo "WARNING: This will destroy all Nextcloud data!"
echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
sleep 10

cd /opt/nextcloud
/opt/bin/docker-compose down -v
rm -rf data/* config/* db/* redis/*
/opt/bin/docker-compose up -d

echo "Nextcloud reset complete. Visit http://localhost:8080 to set up."