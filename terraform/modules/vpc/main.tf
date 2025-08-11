# ===============================================
# VPC module
# ===============================================
resource "aws_vpc" "main_vpc" { 
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

# ===============================================
# Internet gateway
# ===============================================
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "internet_gateway"
  }
}

# ===============================================
# Nat EIP
# ===============================================
resource "aws_eip" "nat_eip" {
  domain   = "vpc"
}

# ===============================================
# Nat gateway
# ===============================================
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.allocation_id
  subnet_id = aws_subnet.subnet.id

  tags = {
    Name = "nat_gateway"
  }
}

# ===============================================
# Subnets
# ===============================================
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.subnet_cidr
  availability_zone = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = var.subnet_name
  }
}

# ===============================================
# Route table
# ===============================================
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.route_cidr_block
    gateway_id = var.route_via
  }

  tags = {
    Name = var.route_table_name
  }
}

# ===============================================
# Route table association
# ===============================================
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

# ===============================================
# Security group
# ===============================================
resource "aws_security_group" "security_group" {
  name        = var.security_group
  description = var.security_group_description
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_port1" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = var.security_group_allow_cidr
  from_port         = var.security_group_from_port
  ip_protocol       = "tcp"
  to_port           = var.security_group_to_port
}


resource "aws_vpc_security_group_egress_rule" "allow_outbound_all" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}