variable "alb_name" {}
variable "lb_security_group" {}
variable "ec2_security_group_id" {
    type = string
}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "user_data" {}
variable "desired_capacity" {}
variable "min_size" {}
variable "max_size" {}