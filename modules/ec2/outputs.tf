output "instance_ids" {
  description = "IDs of created EC2 instances"
  value       = aws_instance.app_instances[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of created EC2 instances"
  value       = aws_instance.app_instances[*].private_ip
}