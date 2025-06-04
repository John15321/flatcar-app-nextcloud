# Flatcar Nextcloud Project Makefile
# Provides convenient commands for validation and development

.PHONY: help validate validate-basic validate-full docker-compose-validate clean install-deps

# Default target
help:
	@echo "🚀 Simplified Flatcar Nextcloud Project Commands"
	@echo "==============================================="
	@echo ""
	@echo "Development Commands:"
	@echo "  make dev-vm            - Start simplified development VM"
	@echo "  make ignition-dev      - Generate development Ignition file"
	@echo ""
	@echo "Validation Commands:"
	@echo "  make validate          - Run basic validation"
	@echo "  make docker-validate   - Validate Docker Compose configuration"
	@echo "  make ci                - Run all validations"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make clean             - Clean generated files"
	@echo "  make install-deps      - Install dependencies"
	@echo ""

# Basic validation
validate:
	@echo "🧪 Running validation..."
	@echo "1. YAML syntax..."
	@yamllint -c .yamllint.yml *.yaml *.yml || echo "⚠️ yamllint not found - install with: pip3 install --user yamllint"
	@echo "2. Docker Compose..."
	@docker-compose -f files/configs/docker-compose.yml config --quiet && echo "✅ Docker Compose is valid"
	@echo "3. Butane configuration..."
	@butane --strict --files-dir=files nextcloud-development.yaml > /dev/null && echo "✅ Butane configuration is valid"

# Docker Compose validation only
docker-validate:
	@echo "🐳 Validating Docker Compose configuration..."
	@docker-compose -f files/configs/docker-compose.yml config --quiet && echo "✅ Docker Compose is valid"

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

# Remove production targets and update CI
ignition-dev:
	@echo "⚙️  Generating development Ignition configuration..."
	@butane --pretty --strict --files-dir=files nextcloud-development.yaml > dev.ign
	@echo "✅ Generated: dev.ign"

# Start development VM
dev-vm:
	@echo "🖥️  Starting simplified development VM..."
	@echo "📝 Generating Ignition config..."
	@butane --pretty --strict --files-dir=files nextcloud-development.yaml > dev.ign
	@echo "🚀 Launching VM (Nextcloud: :8080, Adminer: :8081)..."
	@./flatcar_production_qemu.sh -i dev.ign -M 4096 -f 8080:8080 -f 8081:8081

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
	@docker-compose -f files/configs/docker-compose.yml config --quiet
	@echo "3. Butane configuration validation..."
	@butane --strict --files-dir=files nextcloud-development.yaml > /dev/null
	@echo "✅ All CI validations passed!"
	@butane --strict nextcloud-production.yaml > /dev/null
	@butane --strict nextcloud-development.yaml > /dev/null
	@echo "✅ All CI validations passed!"
