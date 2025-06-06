# =========================================================================
# TERRAFORM VARIABLES FOR NEXTCLOUD PRODUCTION ON AZURE
# =========================================================================

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "nextcloud-production"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "nextcloud-prod"
}

variable "vm_size" {
  description = "Size of the Azure VM"
  type        = string
  default     = "Standard_D2s_v3"

  validation {
    condition = contains([
      "Standard_B2s", "Standard_B2ms", "Standard_B4ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3"
    ], var.vm_size)
    error_message = "VM size must be a valid Azure VM size suitable for Nextcloud."
  }
}

variable "data_disk_size" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.data_disk_size >= 32 && var.data_disk_size <= 4096
    error_message = "Data disk size must be between 32 and 4096 GB."
  }
}

variable "data_disk_type" {
  description = "Type of managed disk for data storage"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition = contains([
      "Standard_LRS", "Premium_LRS", "StandardSSD_LRS"
    ], var.data_disk_type)
    error_message = "Data disk type must be Standard_LRS, Premium_LRS, or StandardSSD_LRS."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string

  validation {
    condition     = can(regex("^ssh-", var.ssh_public_key))
    error_message = "SSH public key must be a valid SSH public key starting with ssh-."
  }
}

variable "ssh_source_ip" {
  description = "Source IP address for SSH access (leave empty for any)"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Domain name for Nextcloud (leave empty to use IP address)"
  type        = string
  default     = ""
}

variable "acme_email" {
  description = "Email address for Let's Encrypt certificate registration"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.acme_email))
    error_message = "ACME email must be a valid email address."
  }
}

variable "create_dns_zone" {
  description = "Create Azure DNS zone for the domain"
  type        = bool
  default     = false
}

variable "enable_traefik_dashboard" {
  description = "Enable Traefik dashboard with subdomain"
  type        = bool
  default     = true
}

variable "enable_backup_storage" {
  description = "Create Azure Storage for backups"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------
# COMPUTED VARIABLES
# -----------------------------------------------------------------------

locals {
  # Use domain if provided, otherwise use public IP
  nextcloud_url = var.domain != "" ? "https://${var.domain}" : "https://[DYNAMIC_IP]"

  # Common tags
  common_tags = {
    Environment = "production"
    Application = "nextcloud"
    ManagedBy   = "terraform"
  }
}
