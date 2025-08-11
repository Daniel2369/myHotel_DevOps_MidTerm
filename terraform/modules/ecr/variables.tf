variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "image_name" {
  description = "Local Docker image name"
  type        = string
}

variable "tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "docker_context" {
  description = "Path to the Docker build context"
  type        = string
}
