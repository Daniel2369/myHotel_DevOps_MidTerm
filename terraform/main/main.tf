# vi ~/.aws/credentiols
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

}

# ===============================================
# Load balancer, Auto scaler and Target group
# ===============================================
module "alb_asg" {
  source = "../modules/alb_asg"

  alb_name          = "myhotel-alb"
  lb_security_group = module.my_vpc.public_security_group_id
  public_subnets    = module.my_vpc.public_subnet_ids
  vpc_id            = module.my_vpc.vpc_id
  ami_id            = "ami-0a7d80731ae1b2435"
  instance_type     = "t3.small"
  key_name          = "vockey"
  desired_capacity  = 2
  min_size          = 2
  max_size          = 4

  user_data = templatefile("${path.module}/ec2-userdata.sh", {
  ecr_repo_url = module.myHotel_APP_ECR.ecr_repo_url
})
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  #<<-EOF
  #   #!/bin/bash
  #   set -euxo pipefail  # exit on error, print commands, fail on pipe errors

  #   LOG_FILE="/var/log/myhotel-init.log"
  #   exec > >(tee -a "$LOG_FILE") 2>&1  # send stdout/stderr to both console and file

  #   echo "=== Starting MyHotel EC2 bootstrap ==="

  #   # Update and install dependencies
  #   apt update -y
  #   apt install -y docker.io unzip curl

  #   echo "Docker installed."
  #   docker --version

  #   # Enable Docker
  #   systemctl enable docker
  #   systemctl start docker
  #   echo "Docker service started."

  #   # Install AWS CLI v2
  #   apt install -y awscli
  #   aws --version

  #   # Setup AWS credentials
  #   mkdir -p /home/ubuntu/.aws

  #   cat <<CREDENTIALS > /home/ubuntu/.aws/credentials
  #   [default]
  #   aws_access_key_id=
  #   aws_secret_access_key=
  #   aws_session_token=
  #   region = us-east-1
  #   CREDENTIALS

  #   chown -R ubuntu:ubuntu /home/ubuntu/.aws
  #   chmod 600 /home/ubuntu/.aws/credentials

  #   # Variables
  #   ECR_URI="${module.myHotel_APP_ECR.ecr_repo_url}"
  #   echo "ECR_URI = $ECR_URI"

  #   ECR_REGISTRY=$(echo $ECR_URI | cut -d'/' -f1)
  #   echo "ECR_REGISTRY = $ECR_REGISTRY"

  #   # Login to ECR
  #   sudo -u ubuntu aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

  #   # Pull and run container
  #   docker pull ${module.myHotel_APP_ECR.ecr_repo_url}:latest
  #   docker run -d -p 80:8000 ${module.myHotel_APP_ECR.ecr_repo_url}:latest

  #   echo "=== MyHotel setup complete ==="
  # EOF
}



# Re-create EC2 instance for testing
# terraform taint aws_instance.hotel_ec2
# terraform apply



# resource "aws_instance" "hotel_ec2" {
#   ami           = "ami-0a7d80731ae1b2435"  # Update for your region, e.g., Amazon Linux 2 AMI
#   instance_type = "t2.micro"
#   key_name      = "vockey"
#   depends_on = [module.myHotel_APP_ECR.build_and_push_done]

#   user_data = <<-EOF
#     #!/bin/bash
#     set -euxo pipefail  # exit on error, print commands, fail on pipe errors

#     LOG_FILE="/var/log/myhotel-init.log"
#     exec > >(tee -a "$LOG_FILE") 2>&1  # send stdout/stderr to both console and file

#     echo "=== Starting MyHotel EC2 bootstrap ==="

#     # Update and install dependencies
#     apt update -y
#     apt install -y docker.io unzip curl

#     echo "Docker installed."
#     docker --version

#     # Enable Docker
#     systemctl enable docker
#     systemctl start docker
#     echo "Docker service started."

#     # Install AWS CLI v2
#     apt install -y awscli
#     aws --version

#     # Setup AWS credentials
#     mkdir -p /home/ubuntu/.aws

#     cat <<CREDENTIALS > /home/ubuntu/.aws/credentials
#     [default]
#     aws_access_key_id=
#     aws_secret_access_key=
#     aws_session_token=
#     region = us-east-1
#     CREDENTIALS

#     chown -R ubuntu:ubuntu /home/ubuntu/.aws
#     chmod 600 /home/ubuntu/.aws/credentials

#     # Variables
#     ECR_URI="${module.myHotel_APP_ECR.ecr_repo_url}"
#     echo "ECR_URI = $ECR_URI"

#     ECR_REGISTRY=$(echo $ECR_URI | cut -d'/' -f1)
#     echo "ECR_REGISTRY = $ECR_REGISTRY"

#     # Login to ECR
#     sudo -u ubuntu aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

#     # Pull and run container
#     docker pull ${module.myHotel_APP_ECR.ecr_repo_url}:latest
#     docker run -d -p 80:8000 ${module.myHotel_APP_ECR.ecr_repo_url}:latest

#     echo "=== MyHotel setup complete ==="
#   EOF

#   tags = {
#     Name = "MyHotelEC2"
#   }
# }
