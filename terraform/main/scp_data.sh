#!/bin/bash
# Copy files to Ansible server using its EIP from Terraform outputs
# Usage: ./scp_data.sh [optional_ansible_server_ip]
# If no IP provided, will fetch from terraform outputs
set -euo pipefail

# Check if IP provided as argument
if [ "$#" -ge 1 ]; then
  ANSIBLE_IP="$1"
  echo "Using provided Ansible server IP: $ANSIBLE_IP"
else
  # Get IP from terraform outputs
  if ! command -v terraform >/dev/null 2>&1; then
    echo "Error: terraform is required to get Ansible server IP"
    echo "Usage: $0 <ansible_server_ip>"
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required. Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
    echo "Or provide IP manually: $0 <ansible_server_ip>"
    exit 1
  fi

  echo "Fetching Ansible server EIP from Terraform outputs..."
  TF_OUT=$(terraform output -json 2>/dev/null || {
    echo "Error: Failed to get terraform outputs. Make sure terraform apply has completed."
    echo "Or provide IP manually: $0 <ansible_server_ip>"
    exit 1
  })

  ANSIBLE_IP=$(echo "$TF_OUT" | jq -r '.ansible_server_eip.value // empty')

  if [[ -z "$ANSIBLE_IP" ]] || [[ "$ANSIBLE_IP" == "null" ]] || [[ "$ANSIBLE_IP" == "empty" ]]; then
    echo "Error: Ansible server EIP not found in Terraform outputs."
    echo "Please run: terraform output ansible_server_eip"
    echo "Or provide IP manually: $0 <ansible_server_ip>"
    exit 1
  fi

  echo "Found Ansible server EIP: $ANSIBLE_IP"
fi

# Find the key file
KEY_PATH="labsuser.pem"
if [[ ! -f "$KEY_PATH" ]]; then
  echo "Error: labsuser.pem not found in current directory"
  exit 1
fi

# Set key permissions
chmod 400 "$KEY_PATH" 2>/dev/null || echo "Warning: Could not set key permissions (may need to run: chmod 400 $KEY_PATH)"

echo ""
echo "Copying files to Ansible server at $ANSIBLE_IP..."
echo "Using key: $KEY_PATH"
echo ""

# Copy files
scp -i "$KEY_PATH" inventory.ini ubuntu@${ANSIBLE_IP}:/home/ubuntu/ && echo "✓ Copied inventory.ini"
scp -i "$KEY_PATH" "$KEY_PATH" ubuntu@${ANSIBLE_IP}:/home/ubuntu/ && echo "✓ Copied labsuser.pem"
scp -i "$KEY_PATH" ../../ansible/ansible-playbook.yml ubuntu@${ANSIBLE_IP}:/home/ubuntu/ && echo "✓ Copied ansible-playbook.yml"
scp -i "$KEY_PATH" ansible_vars.json ubuntu@${ANSIBLE_IP}:/home/ubuntu/ && echo "✓ Copied ansible_vars.json"

echo ""
echo "✓ Successfully copied all files to Ansible server at $ANSIBLE_IP"
echo ""
echo "Next steps:"
echo "  1. SSH to the server: ssh -i $KEY_PATH ubuntu@${ANSIBLE_IP}"
echo "  2. Verify files are present: ls -la ~"
echo "  3. Update inventory.ini with private VM IPs"
echo "  4. Run the Ansible playbook"
