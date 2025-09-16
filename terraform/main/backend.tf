resource "aws_s3_bucket" "backend" {
  bucket = "DevOps2025-Technion-FinalCourse-DBerliant-Bucket"
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform-lock" {
  name = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    name = "TF Locks Table"
  }
}


terraform {
  backend "s3" {
    bucket = "devops2025-technion-finalcourse-dberliant-bucket"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}