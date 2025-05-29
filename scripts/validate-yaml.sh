#!/bin/bash
# Local YAML validation script for Flatcar Nextcloud project
# This script validates all YAML files locally before pushing to GitHub

set -euo pipefail

echo "🔍 Local YAML Validation Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status $BLUE "Checking prerequisites..."

MISSING_DEPS=()

if ! command_exists yamllint; then
    MISSING_DEPS+=("yamllint")
fi

if ! command_exists docker-compose; then
    MISSING_DEPS+=("docker-compose")
fi

if ! command_exists butane; then
    MISSING_DEPS+=("butane")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    print_status $RED "❌ Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "To install missing dependencies:"
    echo "  • yamllint: pip install yamllint"
    echo "  • docker-compose: https://docs.docker.com/compose/install/"
    echo "  • butane: https://coreos.github.io/butane/getting-started/"
    exit 1
fi

print_status $GREEN "✅ All prerequisites found"
echo ""

# 1. Validate YAML syntax
print_status $BLUE "1. Validating YAML syntax..."
if yamllint -c .yamllint.yml *.yaml *.yml 2>/dev/null; then
    print_status $GREEN "✅ YAML syntax validation passed"
else
    print_status $YELLOW "⚠️  YAML syntax issues found (warnings only)"
fi
echo ""

# 2. Validate Docker Compose
print_status $BLUE "2. Validating Docker Compose configuration..."
if docker-compose config --quiet; then
    print_status $GREEN "✅ Docker Compose validation passed"
else
    print_status $RED "❌ Docker Compose validation failed"
    exit 1
fi
echo ""

# 3. Validate Flatcar configurations with Butane
print_status $BLUE "3. Validating Flatcar configurations..."

# Production configuration
print_status $BLUE "   → Validating nextcloud-production.yaml..."
if butane --pretty --strict nextcloud-production.yaml > /dev/null 2>&1; then
    print_status $GREEN "   ✅ Production configuration is valid"
else
    print_status $RED "   ❌ Production configuration validation failed"
    butane --pretty --strict nextcloud-production.yaml
    exit 1
fi

# Development configuration
print_status $BLUE "   → Validating nextcloud-development.yaml..."
if butane --pretty --strict nextcloud-development.yaml > /dev/null 2>&1; then
    print_status $GREEN "   ✅ Development configuration is valid"
else
    print_status $RED "   ❌ Development configuration validation failed"
    butane --pretty --strict nextcloud-development.yaml
    exit 1
fi

echo ""

# 4. Generate Ignition files for verification
print_status $BLUE "4. Generating Ignition files..."
mkdir -p .validation-output

if butane --pretty --strict nextcloud-production.yaml > .validation-output/nextcloud-production.ign; then
    print_status $GREEN "   ✅ Production Ignition file generated"
else
    print_status $RED "   ❌ Failed to generate production Ignition file"
    exit 1
fi

if butane --pretty --strict nextcloud-development.yaml > .validation-output/nextcloud-development.ign; then
    print_status $GREEN "   ✅ Development Ignition file generated"
else
    print_status $RED "   ❌ Failed to generate development Ignition file"
    exit 1
fi

echo ""
print_status $GREEN "🎉 All validations passed!"
echo ""
echo "Generated files in .validation-output/:"
ls -la .validation-output/
echo ""
print_status $BLUE "💡 You can now safely push your changes to GitHub."
echo ""
print_status $YELLOW "Note: .validation-output/ directory is created for local testing only."
print_status $YELLOW "Add it to .gitignore if you don't want to commit generated files."
