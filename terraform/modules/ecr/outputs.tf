output "ecr_repo_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.myHotel.repository_url
}
