variable "name" {
  type = string
}

variable "data_subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "pg_major" {
  type        = string
  default     = "16"
  description = "Version mayor de PostgreSQL. Debe coincidir con la instalada en OCI y Azure."
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.medium" # 2 vCPU / 4 GiB (seccion 12.1 del informe)
  description = "Clase compatible con Multi-AZ y con el laboratorio."
}

variable "db_name" {
  type    = string
  default = "abelito"
}

variable "allocated_storage_gb" {
  type    = number
  default = 20
}

variable "enable_backup" {
  type        = bool
  default     = true
  description = "false si el laboratorio no permite crear roles IAM para AWS Backup."
}

variable "protect_from_destroy" {
  type        = bool
  default     = false
  description = "false en laboratorio (teardown limpio). true en produccion."
}

variable "tags" {
  type    = map(string)
  default = {}
}
