#!/bin/bash
set -euxo pipefail  # exit on error, print commands, fail on pipe errors

# enables ssm
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service


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
ECR_URI="${ecr_repo_url}"
echo "ECR_URI = $ECR_URI"

ECR_REGISTRY=$(echo $ECR_URI | cut -d'/' -f1)
echo "ECR_REGISTRY = $ECR_REGISTRY"

# Login to ECR
sudo -u ubuntu aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull and run container
docker pull ${ecr_repo_url}:latest
docker run -d -p 8000:8000 ${ecr_repo_url}:latest

echo "=== MyHotel setup complete ==="`