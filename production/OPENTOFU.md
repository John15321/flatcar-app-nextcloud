# OpenTofu Support

This production configuration fully supports **OpenTofu** as an alternative to Terraform. OpenTofu is an open-source fork of Terraform that maintains full compatibility while providing additional features and governance.

## Usage

### Using OpenTofu Instead of Terraform

Simply replace `terraform` commands with `tofu` commands:

```bash
# Instead of:
terraform init && terraform plan && terraform apply

# Use:
tofu init && tofu plan && tofu apply
```

### Installation

Install OpenTofu following the [official installation guide](https://opentofu.org/docs/intro/install/):

```bash
# Example for Ubuntu/Debian
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
./install-opentofu.sh --install-method deb

# Or using package manager
sudo apt-get update && sudo apt-get install tofu
```

## Compatibility

- ✅ **Fully compatible** with existing Terraform configurations
- ✅ **Same syntax** and `.tf` files
- ✅ **Same providers** from the Terraform Registry
- ✅ **Same state format** - can migrate between tools
- ✅ **Same workflow** - init, plan, apply, destroy

## Validation and CI/CD

Our automation supports both tools:

- **Makefile**: `make validate-prod` detects and uses available tool (OpenTofu preferred)
- **GitHub Actions**: Validates configurations with both Terraform and OpenTofu
- **Scripts**: All production scripts work with either tool

## Why Choose OpenTofu?

- **Open Source**: True open-source governance and development
- **Community Driven**: Managed by the Linux Foundation
- **Innovation**: Faster feature development and community contributions
- **Compatibility**: Drop-in replacement for Terraform
- **Stability**: Enterprise-grade stability and support

## Migration

No migration needed! Simply:

1. Install OpenTofu
2. Replace `terraform` with `tofu` in your commands
3. Continue using the same configurations and workflows

The same `.tf` files, state files, and providers work seamlessly.
