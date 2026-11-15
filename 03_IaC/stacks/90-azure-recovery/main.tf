provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

data "terraform_remote_state" "backup" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "60-backup-azure/terraform.tfstate"
    region = var.state_region
  }
}

# Apagado por defecto: solo se crea durante el ensayo de restauracion (T15) para no generar costo.
module "recovery" {
  count                = var.enabled ? 1 : 0
  source               = "../../modules/azure/recovery"
  name                 = var.project
  location             = var.location
  cloudflare_cidrs     = var.cloudflare_cidrs
  admin_ssh_public_key = var.admin_ssh_public_key
  backup_container_id  = data.terraform_remote_state.backup.outputs.container_id
  backup_account_name  = data.terraform_remote_state.backup.outputs.storage_account_name
  tags                 = { proyecto = var.project, entorno = "lab", expiracion = var.expiry }
}
