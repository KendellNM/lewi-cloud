variable "state_bucket" {
  type        = string
  description = "Bucket del estado remoto (salida de 00-bootstrap)."
}

variable "state_region" {
  type    = string
  default = "us-east-1"
}

variable "domain" {
  type    = string
  default = "abelito.me"
}

variable "cloudflare_zone_id" {
  type = string
}

variable "active_origin" {
  type        = string
  default     = "aws"
  description = "Origen que sirve abelito.me: aws (normal) u oci (tras activar la recuperacion)."
  validation {
    condition     = contains(["aws", "oci"], var.active_origin)
    error_message = "active_origin debe ser aws u oci."
  }
}

variable "origin_verify_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "oci_enabled" {
  type        = bool
  default     = false
  description = "false = solo AWS (no lee el estado del stack 50). true cuando OCI ya esta desplegado."
}
