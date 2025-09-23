/*
  NOTE: The S3 bucket is created manually (you indicated it's already created).
  We use a data source to reference the existing bucket. The DynamoDB table
  will be created by Terraform from this configuration (resource below).

  Important: Terraform cannot initialize an S3 backend that depends on a
  resource created in the same configuration. That means if you want the
  DynamoDB table to be used for state locking in the S3 backend, the table
  must exist before a terraform init that configures the S3 backend. Two
  common approaches:
    1) Create the DynamoDB table and (optionally) bucket with a small
       one-off bootstrap configuration, then run `terraform init -reconfigure`
       in the main workspace.
    2) Create the DynamoDB table manually (console/CLI). Keep the backend
       as-is and run `terraform init`.
*/

data "aws_s3_bucket" "backend" {
  bucket = "devops2025-technion-finalcourse-dberliant-bucket"
}

/* The DynamoDB lock table is created outside of this configuration using
   the helper script `scripts/setup-tf-backend.sh` (or the terraform/dynamoDB
   bootstrap). We use a data lookup here so Terraform can reference the
   existing table when configuring the S3 backend. */

data "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-locks"
}
/*
  NOTE: The S3 bucket and DynamoDB table used for the Terraform backend should
  typically be created outside the same configuration that uses them as a
  remote backend. If you create them manually, keep the backend block below as
  is and remove the resources. To avoid accidental creation here, these are
  converted to data sources so Terraform will read existing resources instead
  of attempting to create them.
*/

/* Use the existing S3 bucket (data source above). Do NOT keep a data source
   for DynamoDB because we create it here via `aws_dynamodb_table`. If you
   already created the DynamoDB table manually, you can remove the resource
   above and add a data lookup instead. */


terraform {
  backend "s3" {
    bucket = "devops2025-technion-finalcourse-dberliant-bucket"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
  dynamodb_table = "terraform-locks"

  # NOTE: The DynamoDB table creation is defined in this file. Terraform
  # cannot both create the table and enable it in the backend during the
  # same init. To create the table with this configuration run a targeted
  # apply (example below). After the table exists, re-enable the line above
  # and run `terraform init -reconfigure`.

    encrypt = true
  }
}