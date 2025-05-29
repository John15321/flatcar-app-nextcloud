# Flatcar Nextcloud Project Makefile
# Provides convenient commands for validation and development

.PHONY: help validate validate-basic validate-full docker-compose-validate clean install-deps

# Default target
help:
	@echo "🚀 Flatcar Nextcloud Project Commands"
	@echo "======================================"
	@echo ""
	@echo "Validation Commands:"
	@echo "  make validate          - Run basic validation (minimal dependencies)"
	@echo "  make validate-full     - Run comprehensive validation (all tools required)"
	@echo "  make docker-validate   - Validate Docker Compose configuration only"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make install-deps      - Install Python dependencies (yamllint)"
	@echo "  make clean             - Clean validation artifacts"
	@echo ""
	@echo "Development Commands:"
	@echo "  make dev-vm            - Start development VM"
	@echo "  make ignition-prod     - Generate production Ignition file"
	@echo "  make ignition-dev      - Generate development Ignition file"
	@echo ""

# Basic validation (minimal dependencies)
validate:
	@echo "🧪 Running basic validation..."
	@./scripts/validate-basic.sh

# Comprehensive validation (requires all tools)
validate-full:
	@echo "🔍 Running comprehensive validation..."
	@./scripts/validate-yaml.sh

# Docker Compose validation only
docker-validate:
	@echo "🐳 Validating Docker Compose configuration..."
	@docker-compose config --quiet && echo "✅ Docker Compose is valid"

# Install Python dependencies
install-deps:
	@echo "📦 Installing Python dependencies..."
	@pip3 install --user yamllint
	@echo "✅ yamllint installed"
	@echo ""
	@echo "Additional tools to install manually:"
	@echo "  • Butane: https://coreos.github.io/butane/getting-started/"
	@echo "  • Docker Compose: https://docs.docker.com/compose/install/"

# Clean validation artifacts
clean:
	@echo "🧹 Cleaning validation artifacts..."
	@rm -rf .validation-output/
	@rm -rf ignition-artifacts/
	@rm -f *.ign
	@echo "✅ Cleanup complete"

# Generate production Ignition file
ignition-prod:
	@echo "⚙️  Generating production Ignition configuration..."
	@butane --pretty --strict nextcloud-production.yaml > nextcloud-production.ign
	@echo "✅ Generated: nextcloud-production.ign"

# Generate development Ignition file
ignition-dev:
	@echo "⚙️  Generating development Ignition configuration..."
	@butane --pretty --strict nextcloud-development.yaml > nextcloud-development.ign
	@echo "✅ Generated: nextcloud-development.ign"

# Start development VM
dev-vm:
	@echo "🖥️  Starting development VM..."
	@./flatcar_production_qemu.sh

# Quick lint check
lint:
	@echo "🔍 Running YAML linting..."
	@yamllint -c .yamllint.yml *.yaml *.yml

# CI simulation (run all validations like GitHub Actions)
ci:
	@echo "🤖 Simulating CI pipeline..."
	@echo "1. YAML Syntax validation..."
	@yamllint -c .yamllint.yml *.yaml *.yml
	@echo "2. Docker Compose validation..."
	@docker-compose config --quiet
	@echo "3. Flatcar configuration validation..."
	@butane --strict nextcloud-production.yaml > /dev/null
	@butane --strict nextcloud-development.yaml > /dev/null
	@echo "✅ All CI validations passed!"
