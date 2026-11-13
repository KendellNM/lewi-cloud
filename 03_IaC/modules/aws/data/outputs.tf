output "kms_key_arn" {
  value = aws_kms_key.this.arn
}

output "db_identifier" {
  value = aws_db_instance.this.identifier
}

output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_master_secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "db_arn" {
  value = aws_db_instance.this.arn
}

output "allocated_storage_gb" {
  value = aws_db_instance.this.allocated_storage
}

output "objects_bucket" {
  value = aws_s3_bucket.this["objetos"].bucket
}

output "objects_bucket_arn" {
  value = aws_s3_bucket.this["objetos"].arn
}

output "exports_bucket" {
  value = aws_s3_bucket.this["exportaciones"].bucket
}

output "exports_bucket_arn" {
  value = aws_s3_bucket.this["exportaciones"].arn
}
