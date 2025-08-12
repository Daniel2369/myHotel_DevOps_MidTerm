output "my_vpc_id" {
  description = "vpc id"
  value       = aws_vpc.main_vpc.id
}

output "nat_eip_allocation_id" {
  description = "nat_eip_allocation_id"
  value = aws_eip.nat_eip.allocation_id
}

output "Public_subnets_id" {
  description = "Public_subnets_id"
  value = aws_subnet.Public_subnets[*].id
}

output "Private_subnets_id" {
  description = "Private_subnets_id"
  value = aws_subnet.Private_subnets[*].id
}