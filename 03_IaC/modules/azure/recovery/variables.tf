variable "name" {
  type = string
}

variable "location" {
  type        = string
  description = "Region fuera de Norte de Virginia disponible para la suscripcion estudiantil."
}

variable "vnet_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "app_cidr" {
  type    = string
  default = "10.30.11.0/24"
}

variable "data_cidr" {
  type    = string
  default = "10.30.21.0/24"
}

variable "cloudflare_cidrs" {
  type = list(string)
}

variable "app_vm_size" {
  type    = string
  default = "Standard_B2s" # 2 vCPU / 4 GiB
}

variable "db_vm_size" {
  type    = string
  default = "Standard_B2ms" # 2 vCPU / 8 GiB
}

variable "pg_major" {
  type    = string
  default = "16"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "Clave publica SSH. Sin IP publica en la VM de datos; el puerto 22 no se abre en el NSG."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "backup_container_id" {
  type        = string
  default     = ""
  description = "ID del contenedor de copias (stack 60). Si se indica, las VM reciben el rol Storage Blob Data Reader."
}

variable "backup_account_name" {
  type    = string
  default = ""
}
