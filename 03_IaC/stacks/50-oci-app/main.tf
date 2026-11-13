provider "oci" {
  region = data.terraform_remote_state.oci.outputs.region
}

# Origin CA exige la clave de servicio de usuario (Cloudflare > Mi perfil > Claves API > Origin CA Key)
# en la variable de entorno CLOUDFLARE_API_USER_SERVICE_KEY.
provider "cloudflare" {}

locals {
  tags = {
    proyecto    = var.project
    entorno     = "lab"
    propietario = var.owner
    expiracion  = var.expiry
  }
}

data "terraform_remote_state" "oci" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "20-oci-base/terraform.tfstate"
    region = var.state_region
  }
}

# Certificado de origen Cloudflare Origin CA: valido para el modo Full (strict) en el LB de OCI.
resource "tls_private_key" "origin" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "origin" {
  private_key_pem = tls_private_key.origin.private_key_pem
  dns_names       = [var.domain, "*.${var.domain}"]
  subject {
    common_name = var.domain
  }
}

resource "cloudflare_origin_ca_certificate" "origin" {
  csr                = tls_cert_request.origin.cert_request_pem
  hostnames          = [var.domain, "*.${var.domain}"]
  request_type       = "origin-rsa"
  requested_validity = 365
}

module "app" {
  source              = "../../modules/oci/app"
  name                = var.project
  compartment_id      = data.terraform_remote_state.oci.outputs.compartment_id
  availability_domain = data.terraform_remote_state.oci.outputs.availability_domain
  public_subnet_id    = data.terraform_remote_state.oci.outputs.public_subnet_id
  app_subnet_id       = data.terraform_remote_state.oci.outputs.app_subnet_id
  nsg_lb_id           = data.terraform_remote_state.oci.outputs.nsg_lb_id
  nsg_relay_lb_id     = data.terraform_remote_state.oci.outputs.nsg_relay_lb_id
  nsg_app_id          = data.terraform_remote_state.oci.outputs.nsg_app_id
  shape               = var.shape
  ocpus               = var.ocpus
  memory_gb           = var.memory_gb
  pool_min            = var.pool_min
  pool_max            = var.pool_max
  origin_cert_pem     = cloudflare_origin_ca_certificate.origin.certificate
  origin_key_pem      = tls_private_key.origin.private_key_pem
  tags                = local.tags
}
