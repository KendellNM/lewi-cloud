variable "project" {
  type    = string
  default = "e3-abelito"
}

variable "owner" {
  type        = string
  description = "Responsable del laboratorio (etiqueta)."
}

variable "expiry" {
  type        = string
  description = "Fecha de expiracion de los recursos, AAAA-MM-DD (etiqueta)."
}

variable "state_bucket" {
  type        = string
  description = "Bucket del estado remoto (salida de 00-bootstrap)."
}

variable "state_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_region" {
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

variable "asg_min" {
  type    = number
  default = 4
}

variable "asg_max" {
  type    = number
  default = 8
}

variable "origin_verify_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Mismo valor que en 80-dns. Vacio = sin verificacion de cabecera."
}
