variable "vpc_cidr" {
  type = string
  description = "vpc cidr block"
}

variable "subnet_cidr" {
  type = string
  description = "subnet cidr block"
}

variable "subnet_name" {
  type = string
  description = "subnet name"
}

variable "availability_zone" {
  type = string
  description = "availability_zone"
}

variable "map_public_ip_on_launch" {
  type = string
  description = "map_public_ip_on_launch"
}

variable "route_cidr_block" {
  type = string
  description = "route_cidr_block"
}

variable "route_table_name" {
  type = string
  description = "route_table_name"
}

variable "route_via" {
  type = string
  description = "From whom to route"
}

variable "security_group" {
  type = string
  description = "security_group"
}

variable "security_group_description" {
  type = string
  description = "description for the security group"
}

variable "security_group_name" {
  type = string
  description = "security_group_name"
}

variable "security_group_allow_cidr" {
  type = string
  description = "allow cidr block for security group incoming rule"
}

variable "security_group_from_port" {
  type = number
  description = "from port"
}

variable "security_group_to_port" {
  type = number
  description = "to port"
}