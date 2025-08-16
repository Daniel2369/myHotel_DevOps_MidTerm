output "ecr_url" {
  value = module.myHotel_APP_ECR.ecr_repo_url
}

output "alb_asg_url" {
  value = module.alb_asg.alb_dns_name
}

# output "ec2_public_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_instance.hotel_ec2.public_ip
# }
