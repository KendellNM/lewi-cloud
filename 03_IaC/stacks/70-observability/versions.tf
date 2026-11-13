terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
  # bucket y region llegan con: terraform init -backend-config=../../backend.hcl
  backend "s3" {
    key          = "70-observability/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
