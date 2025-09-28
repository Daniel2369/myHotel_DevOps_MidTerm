output "ecr_repo_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.myHotel.repository_url
}

# output "build_and_push_done" {
#   value = null_resource.docker_build_and_push.id
# }