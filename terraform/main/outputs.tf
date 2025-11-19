output "alb_asg_url" {
  value = module.alb_asg.alb_dns_name
}

output "ec2_public_ip" {
  value = aws_instance.hotel_ec2.public_ip
}

output "ansible_server_eip" {
  description = "Static Elastic IP attached to the Ansible bastion host"
  value       = aws_eip.ansible_server.public_ip
}

# Private ASG instances (private IPs) — useful for Ansible inventory when
# connecting to the application instances in the private subnets.
# Find instances created by the ASG by filtering EC2 instances with the
# autoscaling group tag. This avoids relying on an attribute that may not
# be returned by the aws_autoscaling_group data source in some provider
# versions.
data "aws_instances" "asg" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [module.alb_asg.autoscaling_group_name]
  }
}

output "asg_instance_ids" {
  value = data.aws_instances.asg.ids
}

// If you need instance private IPs for Ansible, generate them after apply
// (e.g. with `terraform output -json` and a small script) or use the AWS
// CLI to describe-instances by tag. Returning private IPs via data sources
// that require per-instance for_each can lead to planning issues because
// the instance list isn't known until apply.

output "asg_instance_private_ips" {
  value = []
  description = "(empty) Collect private IPs after apply via terraform output -json or AWS CLI"
}

output "private_key_path" {
  value = "${path.module}/labsuser.pem"
}
