terraform {
  required_version = ">= 1.10"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  # bucket y region llegan con: terraform init -backend-config=../../backend.hcl
  backend "s3" {
    key          = "50-oci-app/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
