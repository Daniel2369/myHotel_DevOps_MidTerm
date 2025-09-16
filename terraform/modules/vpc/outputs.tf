output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = aws_subnet.Public_subnets[*].id
}

output "public_subnet_id_0" {
  value = aws_subnet.Public_subnets[0].id
}


output "private_subnet_ids" {
  description = "IDs of all private subnets"
  value       = aws_subnet.Private_subnets[*].id
}

output "public_security_group_id" {
  description = "Public security group ID"
  value       = aws_security_group.public_security_group.id
}

output "private_security_group_id" {
    description = "Private security group ID"
    value = aws_security_group.private_security_group.id
}