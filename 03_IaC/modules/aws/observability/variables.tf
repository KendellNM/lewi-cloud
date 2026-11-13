variable "name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "db_identifier" {
  type = string
}

variable "allocated_storage_gb" {
  type    = number
  default = 20
}

variable "rds_max_connections" {
  type        = number
  default     = 400
  description = "Maximo de conexiones de la clase elegida (db.t3.medium ~ 400). Ajustar tras medirlo."
}

variable "slot_lag_bytes" {
  type    = number
  default = 536870912 # 512 MiB de WAL retenido
}

variable "vpn_tunnel_ips" {
  type        = list(string)
  description = "IP publicas de los tuneles AWS emparejados con OCI (no los tuneles sin pareja)."
  default     = []
}

variable "alarm_email" {
  type        = string
  default     = ""
  description = "Destinatario autorizado de las alertas; vacio = sin suscripcion."
}

variable "enable_cloudtrail" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_guardduty" {
  type        = bool
  default     = true
  description = "GuardDuty es un detector por cuenta y region: poner false si ya existe."
}
