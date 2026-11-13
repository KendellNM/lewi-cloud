variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8443
}

variable "cloudflare_cidrs" {
  type        = list(string)
  description = "Rangos IPv4 de Cloudflare. Verificar contra https://www.cloudflare.com/ips-v4 antes de aplicar."
  default = [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
    "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
    "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
    "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
  ]
}

variable "tags" {
  type    = map(string)
  default = {}
}
