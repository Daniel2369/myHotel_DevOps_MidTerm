#!/bin/bash
set -euxo pipefail

LOG_FILE="/var/log/myhotel-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting MyHotel EC2 bootstrap ==="

# Update and install dependencies
apt update -y
apt install -y docker.io unzip curl awscli

# Enable Docker
systemctl enable docker
systemctl start docker

# Setup AWS credentials (⚠️ better use IAM role instead of hardcoding)
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
ECR_REGISTRY=$(echo $ECR_URI | cut -d'/' -f1)

# Login to ECR
sudo -u ubuntu aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull and run container
docker pull "${ecr_repo_url}:latest"
docker run -d -p 80:8000 "${ecr_repo_url}:latest"

echo "=== MyHotel setup complete ==="
