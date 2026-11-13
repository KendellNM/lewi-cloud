terraform {
  required_version = ">= 1.10"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
  # bucket y region llegan con: terraform init -backend-config=../../backend.hcl
  backend "s3" {
    key          = "90-azure-recovery/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
