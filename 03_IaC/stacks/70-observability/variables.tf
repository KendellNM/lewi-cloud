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

variable "alarm_email" {
  type        = string
  default     = ""
  description = "Destinatario autorizado de las alertas (vacio = sin suscripcion)."
}

variable "oci_enabled" {
  type        = bool
  default     = false
  description = "false = solo AWS (sin alarmas de VPN ni de OCI). true cuando OCI y la VPN ya estan desplegados."
}
