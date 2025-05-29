#!/bin/bash
# Basic YAML validation script that uses built-in tools only
# This provides basic validation without requiring external dependencies

set -euo pipefail

echo "🧪 Basic YAML Validation (No External Dependencies)"
echo "=================================================="

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

# Function to validate YAML syntax using Python
validate_yaml_python() {
    local file=$1
    python3 -c "
import yaml
import sys
try:
    with open('$file', 'r') as f:
        yaml.safe_load(f)
    print('✅ Valid YAML syntax')
    sys.exit(0)
except yaml.YAMLError as e:
    print(f'❌ YAML Error: {e}')
    sys.exit(1)
except Exception as e:
    print(f'❌ Error: {e}')
    sys.exit(1)
" 2>/dev/null
}

# 1. Check if Python3 is available
if ! command -v python3 >/dev/null 2>&1; then
    print_status $RED "❌ Python3 not found. Cannot perform YAML validation."
    exit 1
fi

# 2. Check if PyYAML is available
if ! python3 -c "import yaml" 2>/dev/null; then
    print_status $YELLOW "⚠️  PyYAML not found. Install with: pip3 install PyYAML"
    print_status $BLUE "Skipping YAML syntax validation..."
else
    print_status $BLUE "1. Validating YAML syntax with Python..."
    
    for file in *.yaml *.yml; do
        if [ -f "$file" ]; then
            echo -n "   → $file: "
            if validate_yaml_python "$file"; then
                true
            else
                print_status $RED "❌ Failed to validate $file"
                exit 1
            fi
        fi
    done
    echo ""
fi

# 3. Validate Docker Compose (if available)
if command -v docker-compose >/dev/null 2>&1; then
    print_status $BLUE "2. Validating Docker Compose configuration..."
    if docker-compose config --quiet 2>/dev/null; then
        print_status $GREEN "   ✅ Docker Compose configuration is valid"
    else
        print_status $RED "   ❌ Docker Compose validation failed"
        echo "   Run 'docker-compose config' for details"
        exit 1
    fi
else
    print_status $YELLOW "   ⚠️  Docker Compose not found. Skipping validation."
fi

echo ""

# 4. Basic file structure validation
print_status $BLUE "3. Validating project structure..."

required_files=(
    "nextcloud-production.yaml"
    "nextcloud-development.yaml"
    "docker-compose.yml"
    "README.md"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    print_status $GREEN "   ✅ All required files present"
else
    print_status $RED "   ❌ Missing required files: ${missing_files[*]}"
    exit 1
fi

echo ""

# 5. Check for sensitive data patterns
print_status $BLUE "4. Checking for potential security issues..."

security_patterns=(
    "password.*=.*[^X]"
    "secret.*=.*[^X]"
    "token.*=.*[^X]"
    "api_key.*=.*[^X]"
)

security_issues=()
for pattern in "${security_patterns[@]}"; do
    if grep -i -E "$pattern" *.yaml *.yml 2>/dev/null | grep -v "CHANGE_ME\|XXX\|placeholder"; then
        security_issues+=("Found potential hardcoded credential")
    fi
done

if [ ${#security_issues[@]} -eq 0 ]; then
    print_status $GREEN "   ✅ No obvious security issues found"
else
    print_status $YELLOW "   ⚠️  Potential security issues detected"
    for issue in "${security_issues[@]}"; do
        echo "   $issue"
    done
fi

echo ""
print_status $GREEN "🎉 Basic validation completed!"
echo ""
print_status $BLUE "💡 For comprehensive validation, install:"
echo "   • yamllint: pip3 install yamllint"
echo "   • butane: https://coreos.github.io/butane/getting-started/"
echo "   • docker-compose: https://docs.docker.com/compose/install/"
echo ""
print_status $BLUE "Then run: ./scripts/validate-yaml.sh"
