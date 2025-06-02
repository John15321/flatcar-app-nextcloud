#!/bin/bash
# Script to run Collabora check after a delay
echo "Waiting 60 seconds for services to fully initialize before running Collabora check..."
sleep 60
echo "Running Collabora diagnostic and setup script..."
/opt/bin/check-collabora.sh
