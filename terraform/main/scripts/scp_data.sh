#!/bin/bash
# Usage: ./scp_data.sh <ansible_server_ip>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <ansible_server_ip>"
  exit 1
fi

ANSIBLE_IP=$1
KEY_PATH="labsuser.pem"

scp -i "$KEY_PATH" inventory.ini ubuntu@${ANSIBLE_IP}:/home/ubuntu/
scp -i "$KEY_PATH" labsuser.pem ubuntu@${ANSIBLE_IP}:/home/ubuntu/
scp -i "$KEY_PATH" ../../ansible/ansible-playbook.yml ubuntu@${ANSIBLE_IP}:/home/ubuntu/
scp -i "$KEY_PATH" ansible_vars.json ubuntu@${ANSIBLE_IP}:/home/ubuntu/

echo "Files copied to ${ANSIBLE_IP}"