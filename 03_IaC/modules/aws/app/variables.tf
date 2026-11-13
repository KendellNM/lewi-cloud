variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "certificate_arn" {
  type        = string
  description = "Certificado ACM validado para el dominio publico."
}

variable "app_port" {
  type    = number
  default = 8443
}

variable "instance_type" {
  type    = string
  default = "t3.small" # 2 vCPU / 2 GiB (seccion 10 del informe)
}

variable "asg_min" {
  type        = number
  default     = 4
  description = "2 por AZ: la perdida de una AZ no deja la aplicacion sin capacidad."
}

variable "asg_max" {
  type    = number
  default = 8
}

variable "enable_access_logs" {
  type    = bool
  default = true
}

variable "cpu_target" {
  type    = number
  default = 60
}

variable "rate_limit_per_5min" {
  type    = number
  default = 1000
}

variable "origin_verify_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Si no es vacio, WAF bloquea peticiones sin la cabecera x-origin-verify (la agrega Cloudflare)."
}

variable "objects_bucket_arn" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
