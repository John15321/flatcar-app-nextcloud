#!/bin/bash
# Periodic Collabora health check and auto-restart if needed

LOG_FILE="/var/log/nextcloud/collabora-check.log"

echo "$(date): Starting Collabora health check" >> "$LOG_FILE"

# Check if Collabora is responding
if ! curl -f http://localhost:9980/ > /dev/null 2>&1; then
    echo "$(date): Collabora not responding, attempting restart" >> "$LOG_FILE"
    /opt/bin/restart-collabora.sh >> "$LOG_FILE" 2>&1
else
    echo "$(date): Collabora is healthy" >> "$LOG_FILE"
fi
