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

# Re-create EC2 instance for testing
# terraform taint aws_instance.hotel_ec2
# terraform apply



resource "aws_instance" "hotel_ec2" {
  ami           = "ami-0a7d80731ae1b2435"  # Update for your region, e.g., Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = "vockey"
  depends_on = [module.myHotel_APP_ECR.build_and_push_done]

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail  # exit on error, print commands, fail on pipe errors

    LOG_FILE="/var/log/myhotel-init.log"
    exec > >(tee -a "$LOG_FILE") 2>&1  # send stdout/stderr to both console and file

    echo "=== Starting MyHotel EC2 bootstrap ==="

    # Update and install dependencies
    apt update -y
    apt install -y docker.io unzip curl

    echo "Docker installed."
    docker --version

    # Enable Docker
    systemctl enable docker
    systemctl start docker
    echo "Docker service started."

    # Install AWS CLI v2
    apt install -y awscli
    aws --version

    # Setup AWS credentials
    mkdir -p /home/ubuntu/.aws

    cat <<CREDENTIALS > /home/ubuntu/.aws/credentials
    [default]
    aws_access_key_id=
    aws_secret_access_key=
    aws_session_token=
    region = us-east-1
    CREDENTIALS

    chown -R ubuntu:ubuntu /home/ubuntu/.aws
    chmod 600 /home/ubuntu/.aws/credentials

    # Variables
    ECR_URI="${module.myHotel_APP_ECR.ecr_repo_url}"
    echo "ECR_URI = $ECR_URI"

    ECR_REGISTRY=$(echo $ECR_URI | cut -d'/' -f1)
    echo "ECR_REGISTRY = $ECR_REGISTRY"

    # Login to ECR
    sudo -u ubuntu aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

    # Pull and run container
    docker pull ${module.myHotel_APP_ECR.ecr_repo_url}:latest
    docker run -d -p 80:8000 ${module.myHotel_APP_ECR.ecr_repo_url}:latest

    echo "=== MyHotel setup complete ==="
  EOF

  tags = {
    Name = "MyHotelEC2"
  }
}
