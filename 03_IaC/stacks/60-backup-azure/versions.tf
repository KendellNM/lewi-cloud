terraform {
  required_version = ">= 1.10"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # bucket y region llegan con: terraform init -backend-config=../../backend.hcl
  backend "s3" {
    key          = "60-backup-azure/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
