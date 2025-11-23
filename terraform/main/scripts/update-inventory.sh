#!/bin/bash
# Update inventory.ini with private IPs from Terraform outputs
# Usage: ./update-inventory.sh
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

# Change to terraform root directory
cd "$TF_ROOT_DIR"

INVENTORY_FILE="$TF_ROOT_DIR/inventory.ini"

# Check prerequisites
if ! command -v terraform >/dev/null 2>&1; then
  echo "Error: terraform is required"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws CLI is required"
  exit 1
fi

# Get Terraform outputs
echo "Fetching Terraform outputs..."
TF_OUT=$(terraform output -json 2>/dev/null || {
  echo "Error: Failed to get terraform outputs. Make sure terraform apply has completed."
  exit 1
})

# Get private_ec2_private_ip (first instance - control plane)
PRIVATE_EC2_IP=$(echo "$TF_OUT" | jq -r '.private_ec2_private_ip.value // empty')

if [[ -z "$PRIVATE_EC2_IP" ]] || [[ "$PRIVATE_EC2_IP" == "null" ]]; then
  echo "Error: private_ec2_private_ip not found in Terraform outputs"
  exit 1
fi

echo "Found private_ec2_private_ip: $PRIVATE_EC2_IP"

# Get ASG name from module output (if available) or query directly
ASG_NAME=$(echo "$TF_OUT" | jq -r '.alb_asg_autoscaling_group_name.value // empty' 2>/dev/null)

# Try to get ASG instance IDs from Terraform outputs first
ASG_IDS_JSON=$(echo "$TF_OUT" | jq -r '.asg_instance_ids.value // []')

# If no ASG name in outputs, try to get it from ASG instance IDs or query by tag
if [[ -z "$ASG_NAME" ]] || [[ "$ASG_NAME" == "null" ]]; then
  # Try to get ASG name from the first instance's tags
  FIRST_INSTANCE_ID=$(echo "$ASG_IDS_JSON" | jq -r '.[0] // empty' 2>/dev/null)
  if [[ -n "$FIRST_INSTANCE_ID" ]] && [[ "$FIRST_INSTANCE_ID" != "null" ]]; then
    ASG_NAME=$(aws ec2 describe-instances \
      --instance-ids "$FIRST_INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].Tags[?Key==`aws:autoscaling:groupName`].Value' \
      --output text \
      --region us-east-1 2>/dev/null || echo "")
  fi
fi

# Get private IPs for ASG instances using AWS CLI
echo ""
echo "Fetching private IPs for ASG instances..."

ASG_IPS=()

# Method 1: If we have ASG instance IDs from Terraform, use them
if [[ "$ASG_IDS_JSON" != "[]" ]] && [[ -n "$ASG_IDS_JSON" ]] && [[ "$ASG_IDS_JSON" != "null" ]]; then
  echo "Using ASG instance IDs from Terraform outputs..."
  # Read ASG instance IDs into array (bash 3.2 compatible)
  ASG_IDS_ARRAY=()
  while IFS= read -r instance_id; do
    if [[ -n "$instance_id" ]] && [[ "$instance_id" != "null" ]]; then
      ASG_IDS_ARRAY+=("$instance_id")
    fi
  done < <(echo "$ASG_IDS_JSON" | jq -r '.[]')
  
  echo "Found ${#ASG_IDS_ARRAY[@]} ASG instance ID(s):"
  for instance_id in "${ASG_IDS_ARRAY[@]}"; do
    echo "  - $instance_id"
  done
  
  # Get private IPs for each instance
  for instance_id in "${ASG_IDS_ARRAY[@]}"; do
    PRIVATE_IP=$(aws ec2 describe-instances \
      --instance-ids "$instance_id" \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
      --output text \
      --region us-east-1 2>/dev/null || echo "")
    
    if [[ -n "$PRIVATE_IP" ]] && [[ "$PRIVATE_IP" != "None" ]] && [[ "$PRIVATE_IP" != "null" ]]; then
      ASG_IPS+=("$PRIVATE_IP")
      echo "  Instance $instance_id: $PRIVATE_IP"
    else
      echo "  Warning: Could not get private IP for instance $instance_id"
    fi
  done
fi

# Method 2: If we have ASG name, query instances by ASG tag (fallback or if IDs method failed)
if [[ ${#ASG_IPS[@]} -eq 0 ]] && [[ -n "$ASG_NAME" ]] && [[ "$ASG_NAME" != "null" ]]; then
  echo "Querying instances by ASG name: $ASG_NAME"
  ASG_IPS_QUERY=$(aws ec2 describe-instances \
    --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text \
    --region us-east-1 2>/dev/null || echo "")
  
  if [[ -n "$ASG_IPS_QUERY" ]]; then
    # Convert space-separated IPs to array (bash 3.2 compatible)
    for ip in $ASG_IPS_QUERY; do
      if [[ -n "$ip" ]] && [[ "$ip" != "None" ]] && [[ "$ip" != "null" ]]; then
        ASG_IPS+=("$ip")
        echo "  Found ASG instance IP: $ip"
      fi
    done
  fi
fi

# Method 3: If still no IPs, try querying by security group or other means
if [[ ${#ASG_IPS[@]} -eq 0 ]]; then
  echo "Warning: Could not get ASG instance IPs. ASG instances may not be ready yet."
  echo "  Tried: Terraform instance IDs and ASG name query"
fi

# Check if we have enough IPs
TOTAL_IPS=$((1 + ${#ASG_IPS[@]}))
if [[ $TOTAL_IPS -lt 3 ]]; then
  echo ""
  echo "Warning: Only found $TOTAL_IPS IP(s). Need 3 IPs for the inventory."
  echo "  - private_ec2_private_ip: $PRIVATE_EC2_IP"
  echo "  - ASG instances: ${#ASG_IPS[@]}"
  echo ""
  echo "The inventory will be updated with available IPs, but you may need to:"
  echo "  1. Wait for ASG instances to be created"
  echo "  2. Run this script again"
  echo ""
fi

# Create backup of inventory.ini
if [[ -f "$INVENTORY_FILE" ]]; then
  cp "$INVENTORY_FILE" "${INVENTORY_FILE}.backup"
  echo "Created backup: ${INVENTORY_FILE}.backup"
fi

# Generate new inventory.ini
cat > "$INVENTORY_FILE" <<EOF
[myhotel_ec2]
ec2-instance-1 ansible_host=${PRIVATE_EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/labsuser.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Add ASG instances (worker nodes)
INSTANCE_NUM=2
for ip in "${ASG_IPS[@]}"; do
  echo "ec2-instance-${INSTANCE_NUM} ansible_host=${ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/labsuser.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> "$INVENTORY_FILE"
  ((INSTANCE_NUM++))
done

echo ""
echo "✓ Successfully updated inventory.ini"
echo ""
echo "Inventory contents:"
cat "$INVENTORY_FILE"
echo ""
echo "Summary:"
echo "  - ec2-instance-1 (control plane): $PRIVATE_EC2_IP"
for i in "${!ASG_IPS[@]}"; do
  instance_num=$((i + 2))
  echo "  - ec2-instance-${instance_num} (worker): ${ASG_IPS[$i]}"
done

