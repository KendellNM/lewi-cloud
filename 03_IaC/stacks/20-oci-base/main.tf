# Autenticacion: ~/.oci/config (perfil DEFAULT) o variables de entorno OCI_* / TF_VAR_*.
provider "oci" {
  region = var.region
}

locals {
  tags           = { proyecto = var.project, entorno = "lab", propietario = var.owner, expiracion = var.expiry }
  compartment_id = var.compartment_id != "" ? var.compartment_id : oci_identity_compartment.this[0].id
}

resource "oci_identity_compartment" "this" {
  count          = var.compartment_id == "" ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = var.project
  description    = "Proyecto final Cloud Computing - Abelito Lewista S.A.C."
  enable_delete  = true
  freeform_tags  = local.tags
}

module "network" {
  source         = "../../modules/oci/network"
  name           = var.project
  compartment_id = local.compartment_id
  vcn_cidr       = "10.20.0.0/16"
  public_cidr    = "10.20.1.0/24"
  app_cidr       = "10.20.11.0/24"
  data_cidr      = "10.20.21.0/24"
  peer_cidr      = var.aws_vpc_cidr
  admin_cidrs    = var.admin_cidrs
  cloudflare_cidrs = coalesce(var.cloudflare_cidrs, [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
    "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
    "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
    "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
  ])
  data_internet_egress = var.data_internet_egress
  tags                 = local.tags
}

module "data" {
  source               = "../../modules/oci/data"
  name                 = var.project
  tenancy_ocid         = var.tenancy_ocid
  compartment_id       = local.compartment_id
  data_subnet_id       = module.network.data_subnet_id
  nsg_db_id            = module.network.nsg_db_id
  shape                = var.shape
  ocpus                = var.ocpus
  memory_gb            = var.memory_gb
  replication_password = var.replication_password
  standby_enabled      = var.standby_enabled
  tags                 = local.tags
}

module "iam" {
  source         = "../../modules/oci/iam"
  name           = var.project
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = local.compartment_id
  bucket_name    = module.data.bucket_name
}
