variable "project" {
  type    = string
  default = "e3-abelito"
}

variable "owner" {
  type = string
}

variable "expiry" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "replication_type" {
  type    = string
  default = "ZRS"
}

variable "writer_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object ID del service principal que usan el relay de OCI y el job de AWS (lo crea el agente 08)."
}

variable "reader_principal_ids" {
  type    = list(string)
  default = []
}
