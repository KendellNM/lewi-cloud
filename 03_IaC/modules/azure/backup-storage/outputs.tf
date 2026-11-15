output "storage_account_name" {
  value = azurerm_storage_account.backups.name
}

output "storage_account_id" {
  value = azurerm_storage_account.backups.id
}

output "container_name" {
  value = azurerm_storage_container.portable.name
}

output "container_id" {
  value = azurerm_storage_container.portable.id
}

output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}
