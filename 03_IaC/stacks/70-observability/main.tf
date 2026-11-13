provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.tags
  }
}

provider "oci" {
  region = var.oci_enabled ? data.terraform_remote_state.oci[0].outputs.region : "us-ashburn-1"
}

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

data "terraform_remote_state" "oci" {
  count   = var.oci_enabled ? 1 : 0
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "20-oci-base/terraform.tfstate"
    region = var.state_region
  }
}

data "terraform_remote_state" "vpn" {
  count   = var.oci_enabled ? 1 : 0
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "30-interconnect/terraform.tfstate"
    region = var.state_region
  }
}

data "terraform_remote_state" "app" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "40-aws-app/terraform.tfstate"
    region = var.state_region
  }
}

module "aws" {
  source                  = "../../modules/aws/observability"
  name                    = var.project
  alb_arn_suffix          = data.terraform_remote_state.app.outputs.alb_arn_suffix
  target_group_arn_suffix = data.terraform_remote_state.app.outputs.target_group_arn_suffix
  asg_name                = data.terraform_remote_state.app.outputs.asg_name
  db_identifier           = data.terraform_remote_state.base.outputs.db_identifier
  allocated_storage_gb    = data.terraform_remote_state.base.outputs.allocated_storage_gb
  vpn_tunnel_ips          = var.oci_enabled ? data.terraform_remote_state.vpn[0].outputs.paired_tunnel_ips : []
  alarm_email             = var.alarm_email
  tags                    = local.tags
}

module "oci" {
  count          = var.oci_enabled ? 1 : 0
  source         = "../../modules/oci/observability"
  name           = var.project
  compartment_id = data.terraform_remote_state.oci[0].outputs.compartment_id
  alarm_email    = var.alarm_email
  tags           = local.tags
}
