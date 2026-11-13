variable "name" {
  type        = string
  description = "Prefijo de nombres (ej. e3-abelito)."
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type        = list(string)
  description = "Exactamente dos zonas de disponibilidad."
  validation {
    condition     = length(var.azs) == 2
    error_message = "Se requieren exactamente 2 AZ."
  }
}

variable "public_cidrs" {
  type = list(string)
}

variable "app_cidrs" {
  type = list(string)
}

variable "data_cidrs" {
  type = list(string)
}

variable "amazon_side_asn" {
  type    = number
  default = 64512
}

variable "nat_per_az" {
  type        = bool
  default     = true
  description = "true = un NAT por AZ (sin SPOF de egreso). false = un NAT (mas barato, SPOF)."
}

variable "enable_interface_endpoints" {
  type        = bool
  default     = false
  description = "Endpoints ssm/ssmmessages/ec2messages/logs/monitoring (5 x 2 AZ ~ USD 0,10/h). Solo si se usa un unico NAT y SSM no debe depender de el."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_flow_logs" {
  type        = bool
  default     = true
  description = "false si el Learner Lab no permite crear roles IAM."
}
