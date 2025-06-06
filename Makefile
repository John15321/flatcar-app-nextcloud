# Flatcar Nextcloud Project Makefile
# Provides convenient commands for validation and development

.PHONY: help validate validate-basic validate-full docker-compose-validate clean install-deps

# Default target
help:
	@echo "🚀 Flatcar Nextcloud Project Commands"
	@echo "===================================="
	@echo ""
	@echo "Development Commands:"
	@echo "  make dev-vm            - Start simplified development VM"
	@echo "  make ignition-dev      - Generate development Ignition file"
	@echo ""
	@echo "Production Commands:"
	@echo "  make ignition-prod     - Generate production Ignition file"
	@echo "  make ignition-https    - Generate production Ignition file with internal HTTPS"
	@echo "  make validate-prod     - Validate production configuration"
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
	@echo "🚀 Launching VM (Nextcloud: :8080, Collabora: :9980, Adminer: :8081)..."
	@./flatcar_production_qemu.sh -i dev.ign -M 4096 -f 8080:8080 -f 8081:8081 -f 9980:9980

# Production targets
ignition-prod:
	@echo "⚙️  Generating production Ignition configuration..."
	@cd production && butane --pretty --strict --files-dir=. nextcloud-production.yaml > ../production.ign
	@echo "✅ Generated: production.ign"
	@echo ""
	@echo "📋 Next steps:"
	@echo "1. Edit production/.env with your domain and credentials"
	@echo "2. Deploy production.ign to your server"
	@echo "3. SSH to server and run: sudo /opt/bin/setup-production.sh"

# Generate production Ignition with internal HTTPS
ignition-https:
	@echo "⚙️  Generating production Ignition configuration with internal HTTPS..."
	@cd production && butane --pretty --strict --files-dir=. nextcloud-production.yaml > ../production-https.ign
	@echo "✅ Generated: production-https.ign"
	@echo ""
	@echo "📋 Next steps:"
	@echo "1. Edit production/.env with your domain and credentials"
	@echo "2. Deploy production-https.ign to your server"
	@echo "3. SSH to server and run: sudo /opt/bin/setup-production.sh --internal-https"
	@echo "4. Start with: docker-compose -f docker-compose.internal-https.yml up -d"

validate-prod:
	@echo "🧪 Validating production configuration..."
	@echo "1. Production Docker Compose..."
	@docker-compose -f production/configs/docker-compose.prod.yml config --quiet && echo "✅ Production Docker Compose is valid"
	@echo "2. Internal HTTPS Docker Compose..."
	@docker-compose -f production/configs/docker-compose.internal-https.yml config --quiet && echo "✅ Internal HTTPS Docker Compose is valid"
	@echo "3. Production Butane configuration..."
	@cd production && butane --strict --files-dir=. nextcloud-production.yaml > /dev/null && echo "✅ Production Butane configuration is valid"
	@echo "4. Terraform/OpenTofu configuration..."
	@cd production/azure && \
	if command -v tofu >/dev/null 2>&1; then \
		tofu fmt -check=true && echo "✅ OpenTofu configuration formatting is valid"; \
	elif command -v terraform >/dev/null 2>&1; then \
		terraform fmt -check=true && echo "✅ Terraform configuration formatting is valid"; \
	else \
		echo "⚠️ Neither OpenTofu nor Terraform found - install one to validate IaC formatting"; \
	fi

# Quick lint check
lint:
	@echo "🔍 Running YAML linting..."
	@find . -name "*.yaml" -o -name "*.yml" | head -10 | xargs yamllint -c .yamllint.yml

# CI simulation (run all validations like GitHub Actions)
ci:
	@echo "🤖 Simulating CI pipeline..."
	@echo "1. YAML Syntax validation..."
	@find . -name "*.yaml" -o -name "*.yml" | head -10 | xargs yamllint -c .yamllint.yml
	@echo "2. Docker Compose validation..."
	@docker-compose -f files/configs/docker-compose.yml config --quiet
	@docker-compose -f production/configs/docker-compose.prod.yml config --quiet
	@docker-compose -f production/configs/docker-compose.internal-https.yml config --quiet
	@echo "3. Butane configuration validation..."
	@butane --strict --files-dir=files nextcloud-development.yaml > /dev/null
	@cd production && butane --strict --files-dir=. nextcloud-production.yaml > /dev/null && echo "✅ Production Butane configuration is valid"
	@echo "✅ All CI validations passed!"
