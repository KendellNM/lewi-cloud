output "app_public_ip" {
  value = azurerm_public_ip.app.ip_address
}

output "db_private_ip" {
  value = azurerm_network_interface.db.private_ip_address
}

output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "backup_account_name" {
  value = var.backup_account_name
}
