variable "project_id" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "location" {
  type    = string
  default = "us-central1"
}

variable "force_destroy" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = {}
}
