#!/bin/bash
# Enhanced production logs viewer
cd /opt/nextcloud

# Default to showing all services if no argument provided
if [ $# -eq 0 ]; then
    echo "Showing logs for all production services..."
    docker-compose logs -f --tail=100
else
    # Show logs for specific service
    docker-compose logs -f --tail=100 "$@"
fi
