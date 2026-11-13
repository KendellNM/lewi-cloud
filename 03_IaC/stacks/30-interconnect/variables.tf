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

variable "state_bucket" {
  type        = string
  description = "Bucket del estado remoto (salida de 00-bootstrap)."
}

variable "state_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "oci_bgp_asn" {
  type        = number
  default     = 31898
  description = "ASN BGP de Oracle (region comercial)."
}

variable "aws_bgp_asn" {
  type        = number
  default     = 64512
  description = "Debe coincidir con amazon_side_asn del VGW."
}

variable "cpe_placeholder_ip" {
  type        = string
  default     = "198.51.100.10"
  description = "IP publica provisional del CPE. Si OCI la rechaza, usar cualquier IP publica valida."
}

variable "aws_tunnel_ips" {
  type        = map(string)
  default     = {}
  description = "IP de los tuneles AWS por camino ({a=..., b=...}). Se completa en la segunda aplicacion (scripts/apply-vpn.sh)."
}
