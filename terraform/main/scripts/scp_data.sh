#!/bin/bash
# Copy files to Ansible server using its EIP from Terraform outputs
# Usage: ./scp_data.sh [optional_ansible_server_ip]
# If no IP provided, will fetch from terraform outputs
set -euo pipefail

# Determine script directory and terraform root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If script is in scripts/ subdirectory, terraform root is parent directory
# Otherwise, assume we're already in terraform root
if [[ "$SCRIPT_DIR" == */scripts ]]; then
  TF_ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  TF_ROOT_DIR="$SCRIPT_DIR"
fi

# Change to terraform root directory for terraform commands and file paths
cd "$TF_ROOT_DIR"

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
    echo "Error: Failed to get terraform outputs. Make sure you're in the terraform directory and terraform apply has completed."
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
KEY_PATH=""
if [[ -f "labsuser.pem" ]]; then
  KEY_PATH="labsuser.pem"
elif [[ -f "$TF_ROOT_DIR/labsuser.pem" ]]; then
  KEY_PATH="$TF_ROOT_DIR/labsuser.pem"
else
  echo "Error: labsuser.pem not found in $TF_ROOT_DIR"
  echo "Please ensure the key file is in the terraform/main directory"
  exit 1
fi

# Set key permissions
chmod 400 "$KEY_PATH" 2>/dev/null || echo "Warning: Could not set key permissions (may need to run: chmod 400 $KEY_PATH)"

# Files to copy
FILES=(
  "inventory.ini"
  "$KEY_PATH"
  "../../ansible/ansible-playbook.yml"
  "ansible_vars.json"
)

echo ""
echo "Copying files to Ansible server at $ANSIBLE_IP..."
echo "Using key: $KEY_PATH"
echo ""

# Copy each file
for file in "${FILES[@]}"; do
  # Get absolute path for files relative to terraform root
  if [[ "$file" == "../../ansible/"* ]]; then
    # Handle the ansible playbook path
    ANSIBLE_PLAYBOOK_PATH="$(cd "$TF_ROOT_DIR" && readlink -f "../../ansible/ansible-playbook.yml" 2>/dev/null || echo "$file")"
    if [[ -f "$ANSIBLE_PLAYBOOK_PATH" ]]; then
      file_path="$ANSIBLE_PLAYBOOK_PATH"
      file_name="ansible-playbook.yml"
    else
      echo "Warning: Could not find $file, skipping..."
      continue
    fi
  else
    # Handle files in terraform root
    file_path="$TF_ROOT_DIR/$file"
    file_name=$(basename "$file")
    
    if [[ ! -f "$file_path" ]]; then
      echo "Warning: Could not find $file, skipping..."
      continue
    fi
  fi

  echo "Copying $file_name..."
  scp -i "$KEY_PATH" "$file_path" ubuntu@${ANSIBLE_IP}:/home/ubuntu/ || {
    echo "Error: Failed to copy $file_name"
    exit 1
  }
done

echo ""
echo "✓ Successfully copied all files to Ansible server at $ANSIBLE_IP"
echo ""
echo "Next steps:"
echo "  1. SSH to the server: ssh -i $KEY_PATH ubuntu@${ANSIBLE_IP}"
echo "  2. Verify files are present: ls -la ~"
echo "  3. Update inventory.ini with private VM IPs"
echo "  4. Run the Ansible playbook"
