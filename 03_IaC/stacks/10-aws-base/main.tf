provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

locals {
  tags = {
    proyecto    = var.project
    entorno     = "lab"
    propietario = var.owner
    expiracion  = var.expiry
  }
}

data "aws_availability_zones" "this" {
  state = "available"
}

module "network" {
  source       = "../../modules/aws/network"
  name         = var.project
  vpc_cidr     = var.vpc_cidr
  azs          = slice(data.aws_availability_zones.this.names, 0, 2)
  public_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
  app_cidrs    = ["10.10.11.0/24", "10.10.12.0/24"]
  data_cidrs   = ["10.10.21.0/24", "10.10.22.0/24"]
  nat_per_az   = var.nat_per_az
  tags         = local.tags
}

module "security" {
  source = "../../modules/aws/security"
  name   = var.project
  vpc_id = module.network.vpc_id
  cloudflare_cidrs = coalesce(var.cloudflare_cidrs, [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
    "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
    "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
    "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
  ])
  tags = local.tags
}

module "data" {
  source               = "../../modules/aws/data"
  name                 = var.project
  data_subnet_ids      = module.network.data_subnet_ids
  rds_sg_id            = module.security.rds_sg_id
  enable_backup        = var.enable_backup
  protect_from_destroy = false
  tags                 = local.tags
}
