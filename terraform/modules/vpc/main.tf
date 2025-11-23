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

# Kubernetes API Server (control plane)
resource "aws_vpc_security_group_ingress_rule" "allow_k8s_api_server" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
  description                  = "Kubernetes API server"
}

# Kubelet API (workers)
resource "aws_vpc_security_group_ingress_rule" "allow_kubelet_api" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  description                  = "Kubelet API"
}

# Kube-scheduler
resource "aws_vpc_security_group_ingress_rule" "allow_kube_scheduler" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 10259
  to_port                      = 10259
  ip_protocol                  = "tcp"
  description                  = "Kube-scheduler"
}

# Kube-controller-manager
resource "aws_vpc_security_group_ingress_rule" "allow_kube_controller_manager" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 10257
  to_port                      = 10257
  ip_protocol                  = "tcp"
  description                  = "Kube-controller-manager"
}

# etcd client communication
resource "aws_vpc_security_group_ingress_rule" "allow_etcd_client" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 2379
  to_port                      = 2380
  ip_protocol                  = "tcp"
  description                  = "etcd client/server"
}

# Calico/VXLAN
resource "aws_vpc_security_group_ingress_rule" "allow_vxlan" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 4789
  to_port                      = 4789
  ip_protocol                  = "udp"
  description                  = "Calico VXLAN"
}

# Calico BGP
resource "aws_vpc_security_group_ingress_rule" "allow_calico_bgp" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 179
  to_port                      = 179
  ip_protocol                  = "tcp"
  description                  = "Calico BGP"
}

# Allow all TCP traffic between nodes in the same security group (for Kubernetes)
resource "aws_vpc_security_group_ingress_rule" "allow_k8s_node_communication" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 10248
  to_port                      = 10255
  ip_protocol                  = "tcp"
  description                  = "Kubernetes node communication ports"
}

# NFS Server port (required for NFS mounts between pods and nodes)
resource "aws_vpc_security_group_ingress_rule" "allow_nfs" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  description                  = "NFS server port"
}

resource "aws_vpc_security_group_ingress_rule" "allow_nfs_udp" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "udp"
  description                  = "NFS server port (UDP)"
}

# NFS mountd port
resource "aws_vpc_security_group_ingress_rule" "allow_nfs_mountd" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 20048
  to_port                      = 20048
  ip_protocol                  = "tcp"
  description                  = "NFS mountd port"
}

resource "aws_vpc_security_group_ingress_rule" "allow_nfs_mountd_udp" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 20048
  to_port                      = 20048
  ip_protocol                  = "udp"
  description                  = "NFS mountd port (UDP)"
}

# NFS dynamic port range (for RPC services like mountd when using dynamic ports)
# Linux typically uses 32768-65535 for ephemeral/dynamic ports
resource "aws_vpc_security_group_ingress_rule" "allow_nfs_dynamic_ports" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 32768
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "NFS dynamic RPC ports (fallback for mountd)"
}

resource "aws_vpc_security_group_ingress_rule" "allow_nfs_dynamic_ports_udp" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 32768
  to_port                      = 65535
  ip_protocol                  = "udp"
  description                  = "NFS dynamic RPC ports UDP (fallback for mountd)"
}

# RPCbind/Portmapper port (required for NFS)
resource "aws_vpc_security_group_ingress_rule" "allow_rpcbind" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 111
  to_port                      = 111
  ip_protocol                  = "tcp"
  description                  = "RPCbind/Portmapper port"
}

resource "aws_vpc_security_group_ingress_rule" "allow_rpcbind_udp" {
  security_group_id            = aws_security_group.private_security_group.id
  referenced_security_group_id = aws_security_group.private_security_group.id
  from_port                    = 111
  to_port                      = 111
  ip_protocol                  = "udp"
  description                  = "RPCbind/Portmapper port (UDP)"
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_all2" {
  security_group_id = aws_security_group.private_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}