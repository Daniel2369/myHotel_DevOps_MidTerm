output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_id" {
  value = aws_lb.this.id
}

output "autoscaling_group_name" {
  description = "Name of the AutoScaling Group managed by this module"
  value       = aws_autoscaling_group.this.name
}
