# Autenticacion: az login (o ARM_* en variables de entorno).
provider "azurerm" {
  subscription_id     = var.subscription_id
  storage_use_azuread = true # la cuenta de almacenamiento no admite claves compartidas
  features {}
}

# Copia portable independiente: fuera de AWS y OCI, region distinta de Norte de Virginia.
module "backup" {
  source               = "../../modules/azure/backup-storage"
  name                 = var.project
  location             = var.location
  replication_type     = var.replication_type
  writer_principal_ids = var.writer_principal_ids
  reader_principal_ids = var.reader_principal_ids
  tags                 = { proyecto = var.project, entorno = "lab", propietario = var.owner, expiracion = var.expiry }
}
