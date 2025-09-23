#!/usr/bin/env bash
# Generate ansible_vars.json from terraform outputs (expects to be run in terraform/main)
set -euo pipefail

OUT_JSON="ansible_vars.json"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required; install it or run without jq"
  exit 1
fi

# Get outputs as json
TF_OUT=$(terraform output -json)

ALB_URL=$(echo "$TF_OUT" | jq -r '.alb_asg_url.value // empty')
ECR_URL=$(echo "$TF_OUT" | jq -r '.ecr_url.value // empty')
EC2_PUBLIC_IP=$(echo "$TF_OUT" | jq -r '.ec2_public_ip.value // empty')
ASG_IDS=$(echo "$TF_OUT" | jq -r '.asg_instance_ids.value // []')

cat > "$OUT_JSON" <<EOF
{
  "alb_asg_url": "${ALB_URL}",
  "ec2_public_ip": "${EC2_PUBLIC_IP}",
  "ecr_url": "${ECR_URL}",
  "aws_access_key_id": "",
  "aws_secret_access_key": "",
  "aws_session_token": ""
}
EOF

echo "Wrote $OUT_JSON. Please fill in AWS credentials (or set them on the Ansible host)."
