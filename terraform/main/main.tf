# vi ~/.aws/credentials
# Add the AWS ID,Secret and Session token
# Edit the user_data under EC2 instance add them too inside the cat command.
# Add incoming Security group rules for SSH and HTTP

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.8.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region
}


module "myHotel_APP_ECR" {
  source         = "../modules/ecr"
  region         = var.region
  repository_name = "myhotel"
  image_name     = "myhotel"
  tag            = "latest"
  docker_context = "../../"
}


module "my_vpc" {
  source = "../modules/vpc"
  depends_on = [ module.myHotel_APP_ECR ]

  # ===============================================
  # VPC module
  # ===============================================
  vpc_cidr       = "10.0.0.0/16"

  # ===============================================
  # Subnets
  # ===============================================
  # PublicSubnets
  public_subnet_count = 2
  availability_zones  = ["us-east-1a", "us-east-1b"]

  public_subnet_cidr = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnet_name = [
    "PublicSubnet1",
    "PublicSubnet2"
  ]

  # PrivateSubnets
  private_subnet_count = 2

  private_subnet_cidr = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  private_subnet_name = [
    "PrivateSubnet1",
    "PrivateSubnet2"
  ]
  
# ===============================================
# Security groups
# ===============================================
# Public Security group
public_security_group = "public_security_group"

# Private Security group
private_security_group = "private_security_group"
alg_id = module.my_vpc.public_security_group_id

}

# ===============================================
# Load balancer, Auto scaler and Target group
# ===============================================
module "alb_asg" {
  source = "../modules/alb_asg"
  depends_on = [ module.myHotel_APP_ECR, module.my_vpc ]

  alb_name          = "myhotel-alb"
  lb_security_group = module.my_vpc.public_security_group_id
  ec2_security_group_id = module.my_vpc.private_security_group_id
  public_subnets    = module.my_vpc.public_subnet_ids
  private_subnets    = module.my_vpc.private_subnet_ids
  vpc_id            = module.my_vpc.vpc_id
  ami_id            = "ami-0a7d80731ae1b2435"
  instance_type     = "t3.small"
  key_name          = "vockey"
  desired_capacity  = 2
  min_size          = 2
  max_size          = 4

  user_data = ""
}
 # user_data = templatefile("${path.module}/ec2-userdata.sh", {
 #  ecr_repo_url = module.myHotel_APP_ECR.ecr_repo_url
 #  })
 #}

# Re-create EC2 instance for testing
# terraform taint aws_instance.hotel_ec2
# terraform apply

# ===============================================
# Ansible machine on public subnet
# ===============================================
resource "aws_security_group" "ansible_server_security_group" {
  name        = "ansible_server_security_group"
  vpc_id      = module.my_vpc.vpc_id

  tags = {
    Name = "ansible_server_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ansible_server_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_outbound_all1" {
  security_group_id = aws_security_group.ansible_server_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "hotel_ec2" {
  ami           = "ami-0bbdd8c17ed981ef9"
  instance_type = "t3.small"
  key_name      = "vockey"
  subnet_id     = module.my_vpc.public_subnet_id_0
  vpc_security_group_ids  = [aws_security_group.ansible_server_security_group.id]
  tags = {
    Name = "ansible-server"
  }
  user_data = file("${path.module}/ansible-server.sh")
}

# =========================================
# Execution steps
# =========================================
# terraform init
# terraform plan -out plan
# terraform apply plan
# terraform output -json > tf_outputs.json
# jq 'map_values(.value)' tf_outputs.json > ansible_vars.json
# cat ansible_vars.json
# Add     aws_access_key_id: ""
          #aws_secret_access_key: ""
          #aws_session_token: ""
# To ansible_vars.json
# Run push_ecr_image.sh
# docker build -t myHotel:latest .
# Edit /main/docker_image_push.sh Add:
#      ECR_URL, local docker image name
# Download pem file and move it to /terraform/main
# chmod 400 labuser.pem


# Take private vm's ip address from the console - I'm here

# Login to the ansible-server using SSH or SSM, install Ansible check SSH connectivity to private VM's

# Configure inventory.ini
# [myhotel_ec2]
# ec2-instance-1 ansible_host=<add private ip 1> ansible_user=ubuntu ansible_ssh_private_key_file=/path/to/labsuser.pem
# ec2-instance-2 ansible_host=<add private ip 2> ansible_user=ubuntu ansible_ssh_private_key_file=/path/to/labsuser.pem

# Test ssh connectivity again
# SCP inventory.ini and pem files from local to the server and the playbook
# Run the playbook

# Check the target group health
# Test application - if unhealthy check private vm's docker container