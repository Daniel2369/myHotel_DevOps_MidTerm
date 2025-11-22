#!/bin/bash
# Copy Helm charts to Ansible server using its EIP from Terraform outputs
# Usage: ./scp_helm_charts.sh [optional_ansible_server_ip]
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

# Find helm-charts directory relative to terraform root
HELM_CHARTS_DIR=""
# Try relative path from terraform/main
if [[ -d "$TF_ROOT_DIR/../../ansible/helm-charts" ]]; then
  HELM_CHARTS_DIR="$(cd "$TF_ROOT_DIR/../../ansible/helm-charts" && pwd)"
elif [[ -d "$TF_ROOT_DIR/../ansible/helm-charts" ]]; then
  HELM_CHARTS_DIR="$(cd "$TF_ROOT_DIR/../ansible/helm-charts" && pwd)"
else
  echo "Error: Could not find helm-charts directory"
  echo "Expected location: $TF_ROOT_DIR/../../ansible/helm-charts"
  echo "Or: $TF_ROOT_DIR/../ansible/helm-charts"
  exit 1
fi

echo ""
echo "Found Helm charts directory: $HELM_CHARTS_DIR"
echo "Copying Helm charts to Ansible server at $ANSIBLE_IP..."
echo "The playbook will then copy them to the control plane node."
echo "Using key: $KEY_PATH"
echo ""

# Create helm-charts directory on Ansible server if it doesn't exist
ssh -i "$KEY_PATH" ubuntu@${ANSIBLE_IP} "mkdir -p /home/ubuntu/helm-charts" || {
  echo "Error: Failed to create helm-charts directory on Ansible server"
  exit 1
}

# Copy myhotel-app directory directly to /home/ubuntu/helm-charts/
# This avoids creating nested helm-charts/helm-charts structure
echo "Copying Helm charts to Ansible server..."

# Copy the myhotel-app subdirectory directly into the destination
scp -r -i "$KEY_PATH" "$HELM_CHARTS_DIR/myhotel-app" ubuntu@${ANSIBLE_IP}:/home/ubuntu/helm-charts/ || {
  echo "Error: Failed to copy helm-charts directory"
  exit 1
}

echo ""
echo "✓ Successfully copied Helm charts to Ansible server at $ANSIBLE_IP"
echo ""
echo "Helm charts are now available at: /home/ubuntu/helm-charts/myhotel-app on Ansible server"
echo ""
echo "Next steps:"
echo "  1. SSH to Ansible server: ssh -i $KEY_PATH ubuntu@${ANSIBLE_IP}"
echo "  2. Verify charts are present: ls -la ~/helm-charts/"
echo "  3. Run the Helm deployment playbook (it will copy charts to control plane automatically)"

