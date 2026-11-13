variable "name" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "ad_index" {
  type    = number
  default = 0
}

variable "data_subnet_id" {
  type = string
}

variable "nsg_db_id" {
  type = string
}

variable "shape" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "Shape Flex. En Always Free usar VM.Standard.A1.Flex (ARM)."
}

variable "ocpus" {
  type    = number
  default = 1
}

variable "memory_gb" {
  type    = number
  default = 4
}

variable "data_volume_gb" {
  type    = number
  default = 50
}

variable "pg_major" {
  type    = string
  default = "16"
}

variable "replication_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Clave del rol de replicacion; se guarda en OCI Vault. Vacio = no crear el secreto."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "standby_enabled" {
  type        = bool
  default     = true
  description = "Segundo PostgreSQL en otro fault domain (standby fisico; la replicacion se configura despues)."
}
