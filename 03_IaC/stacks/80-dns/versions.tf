terraform {
  required_version = ">= 1.10"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
  # bucket y region llegan con: terraform init -backend-config=../../backend.hcl
  backend "s3" {
    key          = "80-dns/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
