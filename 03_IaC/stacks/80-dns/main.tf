# Token en CLOUDFLARE_API_TOKEN (permisos: Zone DNS Edit, Zone Settings Edit, Transform Rules Edit).
provider "cloudflare" {}

data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "40-aws-app/terraform.tfstate"
    region = var.state_region
  }
}

data "terraform_remote_state" "oci" {
  count   = var.oci_enabled ? 1 : 0
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "50-oci-app/terraform.tfstate"
    region = var.state_region
  }
}

locals {
  # Conmutacion MANUAL del origen: cambiar var.active_origin y aplicar, solo tras validar datos y aislar el escritor anterior.
  origins = {
    aws = { type = "CNAME", content = data.terraform_remote_state.aws.outputs.alb_dns_name }
  }
  oci_origin  = var.oci_enabled ? { oci = { type = "A", content = data.terraform_remote_state.oci[0].outputs.web_lb_ip } } : {}
  all_origins = merge(local.origins, local.oci_origin)
  origin      = local.all_origins[var.active_origin]
}

resource "cloudflare_dns_record" "app" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = local.origin.type
  content = local.origin.content
  ttl     = 1 # automatico (requerido con proxy)
  proxied = true
  comment = "Origen activo: ${var.active_origin}"
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_https" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

# Cabecera secreta hacia el origen (WAF de AWS la exige): cierra el acceso directo al ALB.
resource "cloudflare_ruleset" "origin_header" {
  count   = var.origin_verify_secret == "" ? 0 : 1
  zone_id = var.cloudflare_zone_id
  name    = "cabecera-de-origen"
  kind    = "zone"
  phase   = "http_request_late_transform"
  rules = [{
    action      = "rewrite"
    expression  = "true"
    description = "x-origin-verify hacia el origen"
    enabled     = true
    action_parameters = {
      headers = {
        "x-origin-verify" = {
          operation = "set"
          value     = var.origin_verify_secret
        }
      }
    }
  }]
}
