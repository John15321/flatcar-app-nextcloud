#!/bin/bash

# Flatcar QEMU Development Launcher
# This script fixes library path conflicts that can occur with snap packages

echo "🚀 Starting Flatcar Development VM"
echo "=================================="

# Check if dev-ignition.yaml exists
if [ ! -f "dev-ignition.yaml" ]; then
    echo "❌ Error: dev-ignition.yaml not found"
    echo "   Make sure you're in the correct directory and have created the development ignition config"
    exit 1
fi

# Check if Flatcar image exists
if [ ! -f "flatcar_production_qemu_image.img" ]; then
    echo "❌ Error: flatcar_production_qemu_image.img not found"
    echo ""
    echo "Please download the Flatcar image first:"
    echo "  wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2"
    echo "  bunzip2 flatcar_production_qemu_image.img.bz2"
    exit 1
fi

# Clear problematic environment variables that can conflict with QEMU
echo "🔧 Clearing snap-related environment variables..."
unset LD_LIBRARY_PATH
unset LIBGL_DRIVERS_PATH
unset LIBVA_DRIVERS_PATH

# Default options
MEMORY="${1:-4096}"
SNAPSHOT="${2:---snapshot}"

echo "📋 VM Configuration:"
echo "   - Memory: ${MEMORY}MB"
echo "   - Snapshot mode: ${SNAPSHOT}"
echo "   - SSH port: 2222"
echo "   - Nextcloud direct: localhost:8080"
echo "   - Database admin: localhost:8081"
echo ""

echo "🎯 Starting VM with development configuration..."
echo "   This may take 2-3 minutes for initial Docker image downloads"
echo ""

# Run the Flatcar QEMU script with development settings
exec ./flatcar_production_qemu.sh \
    -i dev-ignition.yaml \
    -M "$MEMORY" \
    -f 8080:8080 \
    -f 8081:8081 \
    -- "$SNAPSHOT"
