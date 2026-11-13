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

variable "domain" {
  type    = string
  default = "abelito.me"
}

variable "shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "ocpus" {
  type    = number
  default = 1
}

variable "memory_gb" {
  type    = number
  default = 4
}

variable "pool_min" {
  type    = number
  default = 4
}

variable "pool_max" {
  type    = number
  default = 6
}
