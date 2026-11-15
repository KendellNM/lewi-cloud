variable "name" {
  type = string
}

variable "location" {
  type        = string
  default     = "centralus"
  description = "Region fuera de Norte de Virginia (Central US = Iowa). Verificar disponibilidad en la suscripcion."
}

variable "replication_type" {
  type        = string
  default     = "ZRS"
  description = "ZRS (zonas) por defecto. GRS/GZRS replican a la region pareada (para Central US es East US 2, en Virginia)."
}

variable "writer_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object ID de los principales que escriben (service principal del relay OCI y del job AWS)."
}

variable "reader_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object ID de los principales que leen (identidades de las VM de recuperacion se asignan en el stack 90)."
}

variable "tags" {
  type    = map(string)
  default = {}
}
