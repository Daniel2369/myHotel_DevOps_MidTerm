#!/bin/bash
set -euxo pipefail

# Log output to file
exec > >(tee /var/log/ansible-bootstrap.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Updating system ==="
apt-get update -y
apt-get upgrade -y

echo "=== Installing base dependencies ==="
apt-get install -y \
  software-properties-common \
  python3 \
  python3-pip \
  python3-venv \
  git \
  curl \
  unzip \
  sshpass \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

echo "=== Adding Ansible PPA and installing Ansible ==="
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

echo "=== Installing Docker ==="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "=== Enabling Docker for ubuntu user ==="
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

echo "=== Setting up SSH directory for ubuntu user ==="
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chown ubuntu:ubuntu /home/ubuntu/.ssh

echo "=== Ansible and Docker installation complete ==="
ansible --version
docker --version

