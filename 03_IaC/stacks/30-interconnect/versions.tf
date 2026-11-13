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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # bucket y region llegan con: terraform init -backend-config=../../backend.hcl
  backend "s3" {
    key          = "30-interconnect/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
