locals {
  tags = merge(var.tags, { modulo = "azure-backup-storage" })
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name}-copias"
  location = var.location
  tags     = local.tags
}

# Copia portable independiente del par AWS-OCI. Solo Entra ID (sin claves compartidas), cifrado doble,
# versionado y borrado recuperable: un borrado o corrupcion logica no destruye la unica copia.
resource "azurerm_storage_account" "backups" {
  name                              = "${replace(var.name, "-", "")}${random_string.suffix.result}"
  resource_group_name               = azurerm_resource_group.this.name
  location                          = azurerm_resource_group.this.location
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = var.replication_type
  access_tier                       = "Hot" # sin retencion minima: apto para una demostracion corta
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  infrastructure_encryption_enabled = true
  tags                              = local.tags

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "portable" {
  name                  = "copias-portables"
  storage_account_id    = azurerm_storage_account.backups.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "versions" {
  storage_account_id = azurerm_storage_account.backups.id
  rule {
    name    = "versiones-7-dias"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      version {
        delete_after_days_since_creation = 7
      }
    }
  }
}

# Escritura (relay de OCI y job de AWS): rol de datos acotado al contenedor.
resource "azurerm_role_assignment" "writer" {
  for_each             = toset(var.writer_principal_ids)
  scope                = azurerm_storage_container.portable.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

# Lectura (restauracion): solo ver.
resource "azurerm_role_assignment" "reader" {
  for_each             = toset(var.reader_principal_ids)
  scope                = azurerm_storage_container.portable.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
