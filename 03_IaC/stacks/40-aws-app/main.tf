provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.tags
  }
}

# Token en la variable de entorno CLOUDFLARE_API_TOKEN (permisos: Zone DNS Edit).
provider "cloudflare" {}

locals {
  tags = {
    proyecto    = var.project
    entorno     = "lab"
    propietario = var.owner
    expiracion  = var.expiry
  }
}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "10-aws-base/terraform.tfstate"
    region = var.state_region
  }
}

# Certificado publico ACM validado por DNS en Cloudflare (registro sin proxy).
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_dns_record" "acm_validation" {
  for_each = { for o in aws_acm_certificate.this.domain_validation_options : o.domain_name => o }
  zone_id  = var.cloudflare_zone_id
  name     = each.value.resource_record_name
  type     = each.value.resource_record_type
  content  = each.value.resource_record_value
  ttl      = 60
  proxied  = false
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in cloudflare_dns_record.acm_validation : trimsuffix(r.name, ".")]
}

module "app" {
  source               = "../../modules/aws/app"
  name                 = var.project
  vpc_id               = data.terraform_remote_state.base.outputs.vpc_id
  public_subnet_ids    = data.terraform_remote_state.base.outputs.public_subnet_ids
  app_subnet_ids       = data.terraform_remote_state.base.outputs.app_subnet_ids
  alb_sg_id            = data.terraform_remote_state.base.outputs.alb_sg_id
  app_sg_id            = data.terraform_remote_state.base.outputs.app_sg_id
  certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
  objects_bucket_arn   = data.terraform_remote_state.base.outputs.objects_bucket_arn
  db_secret_arn        = data.terraform_remote_state.base.outputs.db_master_secret_arn
  kms_key_arn          = data.terraform_remote_state.base.outputs.kms_key_arn
  asg_min              = var.asg_min
  asg_max              = var.asg_max
  origin_verify_secret = var.origin_verify_secret
  tags                 = local.tags
}
