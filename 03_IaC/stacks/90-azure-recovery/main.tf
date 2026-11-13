provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Apagado por defecto: solo se crea durante el ensayo de restauracion (T15) para no generar costo.
module "recovery" {
  count                = var.enabled ? 1 : 0
  source               = "../../modules/azure/recovery"
  name                 = var.project
  location             = var.location
  cloudflare_cidrs     = var.cloudflare_cidrs
  admin_ssh_public_key = var.admin_ssh_public_key
  tags                 = { proyecto = var.project, entorno = "lab", expiracion = var.expiry }
}
