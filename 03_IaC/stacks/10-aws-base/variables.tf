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
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "nat_per_az" {
  type        = bool
  default     = true
  description = "true = un NAT por AZ: sin SPOF de egreso y mas barato que endpoints de interfaz (~USD 0,045/h extra vs ~0,10/h)."
}

variable "enable_backup" {
  type        = bool
  default     = true
  description = "false si el Learner Lab no permite crear roles IAM para AWS Backup."
}

variable "cloudflare_cidrs" {
  type        = list(string)
  default     = null
  description = "null = usar la lista por defecto (verificar contra cloudflare.com/ips-v4)."
}
