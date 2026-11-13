output "bucket_name" {
  value = google_storage_bucket.backups.name
}

output "writer_sa_email" {
  value = google_service_account.writer.email
}

output "reader_sa_email" {
  value = google_service_account.reader.email
}
