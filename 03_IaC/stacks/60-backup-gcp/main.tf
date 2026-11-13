provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
}

module "backup" {
  source        = "../../modules/gcp/backup-bucket"
  project_id    = var.gcp_project_id
  bucket_name   = "${var.project}-copias-${var.gcp_project_id}"
  location      = "us-central1"
  force_destroy = true
  labels        = { proyecto = var.project, entorno = "lab" }
}
