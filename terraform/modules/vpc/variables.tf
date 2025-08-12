variable "vpc_cidr" {
  type = string
  description = "vpc cidr block"
}

variable "public_subnet_cidr" {
  type = list(string)
}

variable "public_subnet_name" {
  type = list(string)
}

variable "private_subnet_cidr" {
  type = list(string)
}

variable "private_subnet_name" {
  type = list(string)
}

variable "public_subnet_count" {
  type    = number
  default = 2
}

variable "private_subnet_count" {
  type    = number
  default = 2
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_security_group" {
  type = string
  description = "security_group name"
}

variable "private_security_group" {
  type = string
  description = "security_group name"
}