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
  subnet_id = aws_subnet.Public_subnets[0].id

  tags = {
    Name = "nat_gateway"
  }
}

# ===============================================
# Subnets
# ===============================================
# Public Subnets
resource "aws_subnet" "Public_subnets" {
  count = var.public_subnet_count
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_name[count.index]
  }
}

# Private Subnets
resource "aws_subnet" "Private_subnets" {
  count = var.private_subnet_count
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = var.private_subnet_name[count.index]
  }
}

# ===============================================
# Route table
# ===============================================
# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private_route_table"
  }
}

# ===============================================
# Route table association
# ===============================================
# Public
resource "aws_route_table_association" "public_RA" {
  for_each = { for idx, subnet in aws_subnet.Public_subnets : idx => subnet.id }

  subnet_id      = each.value
  route_table_id = aws_route_table.public_route_table.id
}

# Private
resource "aws_route_table_association" "private_RA" {
  for_each = { for idx, subnet in aws_subnet.Private_subnets : idx => subnet.id }

  subnet_id      = each.value
  route_table_id = aws_route_table.private_route_table.id
}

# ===============================================
# Security group
# ===============================================
# Public Security group
resource "aws_security_group" "public_security_group" {
  name        = var.public_security_group
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "public_security_group"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.public_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_outbound_all1" {
  security_group_id = aws_security_group.public_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Private Security group
resource "aws_security_group" "private_security_group" {
  name        = var.private_security_group
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "private_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_port_8000" {
  security_group_id = aws_security_group.private_security_group.id
  # Allow traffic from the public (ALB) security group to the private instances on port 8000
  referenced_security_group_id         = aws_security_group.public_security_group.id
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}

resource "aws_vpc_security_group_ingress_rule" "allow_port_80" {
  security_group_id = aws_security_group.private_security_group.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_port_443" {
  security_group_id = aws_security_group.private_security_group.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.private_security_group.id
  referenced_security_group_id         = aws_security_group.private_security_group.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_ansible_server" {
  security_group_id = aws_security_group.private_security_group.id
  cidr_ipv4         = "10.0.1.0/24"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_all2" {
  security_group_id = aws_security_group.private_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}