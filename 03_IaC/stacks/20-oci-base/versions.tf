terraform {
  required_version = ">= 1.10"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
  # bucket y region llegan con: terraform init -backend-config=../../backend.hcl
  backend "s3" {
    key          = "20-oci-base/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
