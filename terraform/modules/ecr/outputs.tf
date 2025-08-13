output "ecr_repo_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.myHotel.repository_url
}

output "build_and_push_done" {
  value = null_resource.docker_build_and_push.id
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}
