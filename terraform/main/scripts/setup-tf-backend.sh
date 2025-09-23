#!/bin/bash

# === CONFIGURATION ===
REGION="us-east-1"
S3_BUCKET="devops2025-technion-finalcourse-dberliant-bucket"
DYNAMODB_TABLE="terraform-locks"

# === Create S3 Bucket (if it doesn't exist) ===
echo "Checking if S3 bucket '$S3_BUCKET' exists..."
if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
  echo "S3 bucket '$S3_BUCKET' already exists."
else
  echo "Creating S3 bucket '$S3_BUCKET'..."

  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$S3_BUCKET" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$S3_BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi

  echo "S3 bucket created."
fi

# === Enable Versioning on the S3 Bucket ===
echo "Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
  --bucket "$S3_BUCKET" \
  --versioning-configuration Status=Enabled
echo "Versioning enabled."

# === Create DynamoDB Table (if it doesn't exist) ===
echo "Checking if DynamoDB table '$DYNAMODB_TABLE' exists..."
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>/dev/null; then
  echo "DynamoDB table '$DYNAMODB_TABLE' already exists."
else
  echo "Creating DynamoDB table '$DYNAMODB_TABLE'..."
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --region "$REGION" \
    --billing-mode PAY_PER_REQUEST \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH

  echo "Waiting for DynamoDB table to become active..."
  aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
  echo "DynamoDB table created and active."
fi

echo "Terraform backend resources are ready."
