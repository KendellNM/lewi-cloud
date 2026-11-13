resource "google_storage_bucket" "backups" {
  project                     = var.project_id
  name                        = var.bucket_name
  location                    = var.location
  storage_class               = "STANDARD" # sin retencion minima: apto para una demo corta
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.force_destroy

  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 7
      with_state                 = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
  labels = var.labels
}

# Identidad de carga: puede crear objetos, no leerlos ni borrarlos.
resource "google_service_account" "writer" {
  project      = var.project_id
  account_id   = "e3-backup-writer"
  display_name = "Carga de copias portables (solo crear)"
}

resource "google_storage_bucket_iam_member" "writer" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.writer.email}"
}

# Identidad de restauracion (Azure): solo lectura.
resource "google_service_account" "reader" {
  project      = var.project_id
  account_id   = "e3-backup-reader"
  display_name = "Restauracion de copias (solo lectura)"
}

resource "google_storage_bucket_iam_member" "reader" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.reader.email}"
}
