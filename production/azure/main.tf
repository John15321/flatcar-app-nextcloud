# =========================================================================
# NEXTCLOUD PRODUCTION ON AZURE - TERRAFORM/OPENTOFU CONFIGURATION
# =========================================================================
# This configuration is fully compatible with both Terraform and OpenTofu
# Use either 'terraform' or 'tofu' commands interchangeably

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# -----------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------

resource "azurerm_resource_group" "nextcloud" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "production"
    Application = "nextcloud"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------

resource "azurerm_virtual_network" "nextcloud" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.nextcloud.location
  resource_group_name = azurerm_resource_group.nextcloud.name

  tags = azurerm_resource_group.nextcloud.tags
}

resource "azurerm_subnet" "nextcloud" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.nextcloud.name
  virtual_network_name = azurerm_virtual_network.nextcloud.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -----------------------------------------------------------------------
# SECURITY GROUPS
# -----------------------------------------------------------------------

resource "azurerm_network_security_group" "nextcloud" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.nextcloud.location
  resource_group_name = azurerm_resource_group.nextcloud.name

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_ip != "" ? var.ssh_source_ip : "*"
    destination_address_prefix = "*"
  }

  # HTTP access (for Let's Encrypt)
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS access
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.nextcloud.tags
}

resource "azurerm_subnet_network_security_group_association" "nextcloud" {
  subnet_id                 = azurerm_subnet.nextcloud.id
  network_security_group_id = azurerm_network_security_group.nextcloud.id
}

# -----------------------------------------------------------------------
# PUBLIC IP
# -----------------------------------------------------------------------

resource "azurerm_public_ip" "nextcloud" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.nextcloud.name
  location            = azurerm_resource_group.nextcloud.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.nextcloud.tags
}

# -----------------------------------------------------------------------
# NETWORK INTERFACE
# -----------------------------------------------------------------------

resource "azurerm_network_interface" "nextcloud" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.nextcloud.location
  resource_group_name = azurerm_resource_group.nextcloud.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nextcloud.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nextcloud.id
  }

  tags = azurerm_resource_group.nextcloud.tags
}

# -----------------------------------------------------------------------
# STORAGE
# -----------------------------------------------------------------------

resource "azurerm_storage_account" "nextcloud" {
  count = var.enable_backup_storage ? 1 : 0

  name                     = "${replace(var.prefix, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.nextcloud.name
  location                 = azurerm_resource_group.nextcloud.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = azurerm_resource_group.nextcloud.tags
}

resource "azurerm_storage_container" "backups" {
  count = var.enable_backup_storage ? 1 : 0

  name               = "nextcloud-backups"
  storage_account_id = azurerm_storage_account.nextcloud[0].id
}

# -----------------------------------------------------------------------
# MANAGED DISK FOR DATA
# -----------------------------------------------------------------------

resource "azurerm_managed_disk" "nextcloud_data" {
  name                 = "${var.prefix}-data-disk"
  location             = azurerm_resource_group.nextcloud.location
  resource_group_name  = azurerm_resource_group.nextcloud.name
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size

  tags = azurerm_resource_group.nextcloud.tags
}

# -----------------------------------------------------------------------
# VIRTUAL MACHINE
# -----------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "nextcloud" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.nextcloud.name
  location            = azurerm_resource_group.nextcloud.location
  size                = var.vm_size
  admin_username      = "core"

  # Disable password authentication and use SSH keys
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nextcloud.id,
  ]

  admin_ssh_key {
    username   = "core"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "kinvolk"
    offer     = "flatcar-container-linux-free"
    sku       = "stable"
    version   = "latest"
  }

  # Accept Flatcar Container Linux terms
  plan {
    name      = "stable"
    product   = "flatcar-container-linux-free"
    publisher = "kinvolk"
  }

  # Cloud-init configuration for Nextcloud production
  custom_data = base64encode(templatefile("${path.module}/../nextcloud-production.yaml", {
    ssh_public_key = var.ssh_public_key
    domain         = var.domain != "" ? var.domain : azurerm_public_ip.nextcloud.ip_address
    acme_email     = var.acme_email
    public_ip      = azurerm_public_ip.nextcloud.ip_address
  }))

  tags = azurerm_resource_group.nextcloud.tags
}

# Attach data disk
resource "azurerm_virtual_machine_data_disk_attachment" "nextcloud_data" {
  managed_disk_id    = azurerm_managed_disk.nextcloud_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.nextcloud.id
  lun                = "0"
  caching            = "ReadWrite"
}

# -----------------------------------------------------------------------
# DNS ZONE (if domain provided)
# -----------------------------------------------------------------------

resource "azurerm_dns_zone" "nextcloud" {
  count = var.domain != "" && var.create_dns_zone ? 1 : 0

  name                = var.domain
  resource_group_name = azurerm_resource_group.nextcloud.name

  tags = azurerm_resource_group.nextcloud.tags
}

resource "azurerm_dns_a_record" "nextcloud" {
  count = var.domain != "" && var.create_dns_zone ? 1 : 0

  name                = "@"
  zone_name           = azurerm_dns_zone.nextcloud[0].name
  resource_group_name = azurerm_resource_group.nextcloud.name
  ttl                 = 300
  records             = [azurerm_public_ip.nextcloud.ip_address]

  tags = azurerm_resource_group.nextcloud.tags
}

resource "azurerm_dns_cname_record" "collabora" {
  count = var.domain != "" && var.create_dns_zone ? 1 : 0

  name                = "collabora"
  zone_name           = azurerm_dns_zone.nextcloud[0].name
  resource_group_name = azurerm_resource_group.nextcloud.name
  ttl                 = 300
  record              = var.domain

  tags = azurerm_resource_group.nextcloud.tags
}

resource "azurerm_dns_cname_record" "traefik" {
  count = var.domain != "" && var.create_dns_zone && var.enable_traefik_dashboard ? 1 : 0

  name                = "traefik"
  zone_name           = azurerm_dns_zone.nextcloud[0].name
  resource_group_name = azurerm_resource_group.nextcloud.name
  ttl                 = 300
  record              = var.domain

  tags = azurerm_resource_group.nextcloud.tags
}
