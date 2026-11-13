variable "name" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "vcn_cidr" {
  type = string
}

variable "public_cidr" {
  type = string
}

variable "app_cidr" {
  type = string
}

variable "data_cidr" {
  type = string
}

variable "peer_cidr" {
  type        = string
  description = "CIDR de la VPC de AWS (destino por DRG)."
}

variable "app_port" {
  type    = number
  default = 8443
}

variable "cloudflare_cidrs" {
  type        = list(string)
  description = "Rangos IPv4 de Cloudflare (verificar contra https://www.cloudflare.com/ips-v4)."
  default = [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
    "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
    "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
    "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
  ]
}

variable "admin_cidrs" {
  type        = list(string)
  description = "IP desde las que se permite crear sesiones del servicio Bastion (la IP del operador /32)."
}

variable "data_internet_egress" {
  type        = bool
  default     = false
  description = "true solo mientras se instalan paquetes en la subred de datos."
}

variable "tags" {
  type    = map(string)
  default = {}
}
