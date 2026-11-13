variable "project" {
  type    = string
  default = "e3-abelito"
}

variable "expiry" {
  type = string
}

variable "enabled" {
  type        = bool
  default     = false
  description = "true solo durante el ensayo de recuperacion."
}

variable "subscription_id" {
  type = string
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Region fuera de Norte de Virginia (eastus); verificar disponibilidad en la suscripcion estudiantil."
}

variable "admin_ssh_public_key" {
  type = string
}

variable "cloudflare_cidrs" {
  type = list(string)
  default = [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
    "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
    "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
    "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
  ]
}
