terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.8.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region
}


module "myHotel_APP_ECR" {
  source         = "../modules/ecr"
  region         = var.region
  repository_name = "myhotel"
  image_name     = "myhotel"
  tag            = "latest"
  docker_context = "../../"
}