variable "name" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
