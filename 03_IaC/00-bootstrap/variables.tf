variable "project" {
  type    = string
  default = "e3-abelito"
}

variable "owner" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "gcp_project_id" {
  type        = string
  default     = ""
  description = "Si no es vacio, crea un bucket GCS para la copia del estado."
}
