variable "name" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "nsg_lb_id" {
  type = string
}

variable "nsg_relay_lb_id" {
  type = string
}

variable "nsg_app_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8443
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
  type        = number
  default     = 4
  description = "2 por fault domain. Alta disponibilidad prioritaria sobre el costo (supera Always Free)."
}

variable "pool_max" {
  type    = number
  default = 6
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "rate_limit_per_min" {
  type    = number
  default = 600
}

variable "origin_cert_pem" {
  type        = string
  description = "Certificado de origen (Cloudflare Origin CA) para el LB publico."
}

variable "origin_key_pem" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
