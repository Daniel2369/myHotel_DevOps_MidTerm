#!/usr/bin/env bash
set -euo pipefail

# destroy-infra.sh
# Safely destroy the Terraform-managed infrastructure in terraform/main
# Optionally remove the S3 backend state and DynamoDB lock table when
# called with --cleanup-backend (useful to fully tear down everything).

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SCRIPTDIR%/scripts}"

# Configuration - adjust if you used a different bucket/name
S3_BUCKET="devops2025-technion-finalcourse-dberliant-bucket"
STATE_KEY="global/s3/terraform.tfstate"
DYNAMODB_TABLE="terraform-locks"
REGION="us-east-1"

usage() {
  cat <<EOF
Usage: $0 [--cleanup-backend]

--cleanup-backend   After terraform destroy, delete the remote state file,
                    empty & delete the S3 bucket and delete the DynamoDB table.

IMPORTANT: This script will auto-approve destructive operations. Ensure
you have the correct AWS credentials and you really want to destroy the
environment before running.
EOF
  exit 1
}

CLEANUP_BACKEND=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cleanup-backend) CLEANUP_BACKEND=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

echo "== Destroy script starting (auto-approve)"
echo "Working directory: $ROOT/"

if [ -d "$ROOT" ]; then
  cd "$ROOT" || { echo "Failed to cd $ROOT"; exit 2; }
else
  echo "Expected directory $ROOT does not exist. Aborting." >&2
  exit 2
fi

echo "Initializing Terraform (backend will be used)"
terraform init -input=false -reconfigure

echo "Running terraform destroy -auto-approve"
terraform destroy -auto-approve

if [ "$CLEANUP_BACKEND" = true ] ; then
  echo "\n== Cleaning up backend resources (S3 + DynamoDB)"

  # Delete the remote state file (if present)
  if command -v aws >/dev/null 2>&1; then
    echo "Removing state file s3://$S3_BUCKET/$STATE_KEY"
    aws s3 rm "s3://$S3_BUCKET/$STATE_KEY" --region "$REGION" || true
    aws s3 rm "s3://$S3_BUCKET/${STATE_KEY}.backup" --region "$REGION" || true

    echo "Emptying S3 bucket $S3_BUCKET"
    aws s3 rm "s3://$S3_BUCKET" --recursive --region "$REGION" || true

    echo "Deleting S3 bucket $S3_BUCKET"
    aws s3api delete-bucket --bucket "$S3_BUCKET" --region "$REGION" || true

    echo "Deleting DynamoDB table $DYNAMODB_TABLE"
    aws dynamodb delete-table --table-name "$DYNAMODB_TABLE" --region "$REGION" || true
    echo "Waiting for DynamoDB table to be deleted (if it existed)..."
    aws dynamodb wait table-not-exists --table-name "$DYNAMODB_TABLE" --region "$REGION" || true
  else
    echo "aws CLI not found; cannot cleanup backend. Please run the cleanup manually."
  fi
fi

echo "\n== Destroy complete"
