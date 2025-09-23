Bootstrap DynamoDB table for Terraform state locking

This folder creates the DynamoDB table used for Terraform state locking
(`terraform-locks`). Run this BEFORE running `terraform init` with the S3
backend enabled in the main workspace.

Steps:

1. Initialize the bootstrap workspace:

   cd terraform/dynamoDB
   terraform init

2. Create the DynamoDB table:

   terraform apply -auto-approve

3. After the table exists, reconfigure the main workspace to use it:

   cd ../../terraform/main
   # uncomment `dynamodb_table = "terraform-locks"` in backend.tf if commented
   terraform init -reconfigure

4. Continue with the normal workflow:

   terraform plan -out plan
   terraform apply plan

Notes:
- You can also create the table manually in the AWS console/CLI instead of
  using this bootstrap.
- Keep AWS credentials available in your environment when running these
  commands (or use an AWS profile):

  export AWS_PROFILE=your-profile
