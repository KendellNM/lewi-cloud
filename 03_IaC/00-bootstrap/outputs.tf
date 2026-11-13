output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

output "backend_hcl" {
  description = "Contenido para ../backend.hcl (usado con terraform init -backend-config)."
  value       = "bucket = \"${aws_s3_bucket.state.bucket}\"\nregion = \"${var.aws_region}\"\n"
}

output "state_copy_bucket" {
  value = try(google_storage_bucket.state_copy[0].name, null)
}
