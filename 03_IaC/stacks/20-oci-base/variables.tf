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

variable "region" {
  type    = string
  default = "us-ashburn-1"
}

variable "tenancy_ocid" {
  type = string
}

variable "compartment_id" {
  type        = string
  default     = ""
  description = "Vacio = crear un compartment del proyecto bajo la tenancy."
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "admin_cidrs" {
  type        = list(string)
  description = "IP /32 del operador autorizada a crear sesiones del servicio Bastion."
}

variable "cloudflare_cidrs" {
  type    = list(string)
  default = null
}

variable "data_internet_egress" {
  type    = bool
  default = false
}

variable "shape" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "VM.Standard.A1.Flex (ARM) si se usa Always Free; la imagen de aplicacion debe ser compatible."
}

variable "ocpus" {
  type    = number
  default = 1
}

variable "memory_gb" {
  type    = number
  default = 4
}

variable "replication_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "standby_enabled" {
  type    = bool
  default = true
}
