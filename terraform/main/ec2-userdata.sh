#!/bin/bash
set -euxo pipefail  # exit on error, print commands, fail on pipe errors

LOG_FILE="/var/log/myhotel-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # send stdout/stderr to both console and file

echo "=== Starting MyHotel EC2 bootstrap ==="

# --- Wait for apt/dpkg lock and update ---
echo "Checking for and waiting on apt/dpkg locks..."
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "Waiting for other apt/dpkg processes to finish..."
    sleep 5
done

echo "Updating apt cache..."
apt-get update -y || { echo "Failed to update apt cache. Exiting."; exit 1; }

# --- Install dependencies ---
echo "Installing dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  docker.io unzip curl awscli snapd || { echo "Failed to install dependencies. Exiting."; exit 1; }

echo "Installation complete."

# Update and install dependencies
#sudo apt-get update -y
#sudo apt-get install -y docker.io unzip curl

echo "Docker installed."
docker --version

# Enable Docker
systemctl enable docker
systemctl start docker
echo "Docker service started."

# Install AWS CLI v2
sudo apt-get install -y awscli
aws --version

# Setup AWS credentials
sudo mkdir -p /home/ubuntu/.aws

sudo cat <<CREDENTIALS > /home/ubuntu/.aws/credentials
[default]
aws_access_key_id="ASIAZCQKSLTAN3ACEZR2"
aws_secret_access_key="FjiUF3KLy+wUCF8vG4hn75qE2JIVcOfCu0SPrnie"
aws_session_token="IQoJb3JpZ2luX2VjEBcaCXVzLXdlc3QtMiJIMEYCIQCOvjjQZiPSaN/yxrFNQ8rtaMr9RqdOOLC1woMeQqx1hgIhAJzAAQYypiPBwxnBI1d3/f99f7H/ntjjFDQ30tLCXdPRKrwCCJD//////////wEQARoMNjIzODY2MTc0NjU2IgwCLKZHhVcJ6pNEf+cqkAIOhmBUA9XPfochzMoNnYoPHv1nYNEOvtVDYMtf7OF+UqWfmNF9vDyKwWDpOTBmzn05i1OHQdHOl+Ka224N4nyXEOeJb1ruGpPBS1I+lk9KudcLVi2mHYfWk0oFUsSnhOzAC3fTiDTIirofcRixdzEOtmLxbEo4SWlwlpCC2rq/oSRkXpt7LV8clPoiz4Eqcml2HDwj7wrJU9Z4FcUgIdsFbkvUtXLe4o+QNVOzbVGjhDBfFZBpiNOP+ncOmn5wu2crfsRHo8RQ5HHUFgalu326e+PmP+APoHdpoi7N3zfKBSn8f8h7QLbSfxZbvK+LicR0Ptg8UL+gg5b10ycYR1co8iqpcuAJUVD/nfmao5qU4jCW+qXGBjqcAd62y/YWkH7y+M5oqjEhS6HGuFk6igaoeJv/Ee7iT6eYaSJlkmoOCkfMjz+4dRocMMwaWWfbgRfYTOOjZCj7wouWIexbnrIRlIcLk9xZo8oaTisJU5kDvO5Q50dgbxZ+37hfBUtvZJjHIR+o5WApFL42l34JEt3XUt4bpEAF2S0ckS3eGVleMLhSMIBBAGyQuZQxZnIzWQUovGndzg=="
region = us-east-1
CREDENTIALS

sudo chown -R ubuntu:ubuntu /home/ubuntu/.aws
sudo chmod 600 /home/ubuntu/.aws/credentials

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

# --- Enable SSM Agent (after system is ready) ---
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true
echo "SSM Agent enabled"