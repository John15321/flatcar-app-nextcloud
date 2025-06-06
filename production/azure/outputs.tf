# =========================================================================
# TERRAFORM OUTPUTS FOR NEXTCLOUD PRODUCTION ON AZURE
# =========================================================================

output "nextcloud_url" {
  description = "URL to access Nextcloud"
  value       = var.domain != "" ? "https://${var.domain}" : "https://${azurerm_public_ip.nextcloud.ip_address}"
}

output "collabora_url" {
  description = "URL to access Collabora Online"
  value       = var.domain != "" ? "https://collabora.${var.domain}" : "https://${azurerm_public_ip.nextcloud.ip_address}:9980"
}

output "traefik_dashboard_url" {
  description = "URL to access Traefik dashboard"
  value       = var.enable_traefik_dashboard ? (var.domain != "" ? "https://traefik.${var.domain}" : "https://${azurerm_public_ip.nextcloud.ip_address}:8080") : "Not enabled"
}

output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.nextcloud.ip_address
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh core@${azurerm_public_ip.nextcloud.ip_address}"
}

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.nextcloud.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.nextcloud.name
}

output "storage_account_name" {
  description = "Name of the storage account for backups"
  value       = var.enable_backup_storage ? azurerm_storage_account.nextcloud[0].name : "Not created"
}

output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone (if created)"
  value       = var.create_dns_zone && var.domain != "" ? azurerm_dns_zone.nextcloud[0].name_servers : []
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    1. SSH to the server: ssh core@${azurerm_public_ip.nextcloud.ip_address}
    2. Check deployment status: systemctl status nextcloud-production
    3. View logs: journalctl -u nextcloud-production -f
    4. Access Nextcloud: ${var.domain != "" ? "https://${var.domain}" : "https://${azurerm_public_ip.nextcloud.ip_address}"}
    
    ${var.domain != "" ? "" : "⚠️  Using IP address - SSL certificates will be self-signed or require manual setup"}
    ${var.create_dns_zone && var.domain != "" ? "\n📋 Update your domain's name servers to: ${join(", ", azurerm_dns_zone.nextcloud[0].name_servers)}" : ""}
  EOT
}
