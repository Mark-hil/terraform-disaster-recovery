output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = module.security_group.app_security_group_id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.primary_rds.rds_endpoint
}

# output "rds_port" {
#   description = "RDS port"
#   value       = module.primary_rds.rds_port
# }

output "rds_username" {
  description = "RDS username"
  value       = module.primary_rds.rds_username
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.primary_rds.rds_database_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.s3_bucket_arn
}

output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = module.s3.s3_bucket_id
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = module.s3.s3_bucket_domain_name
}

# ALB outputs
output "alb_listener_arn" {
  description = "ARN of the ALB listener"
  value       = module.alb.listener_arn
}

output "alb_target_group_arn" {
  description = "ARN of the primary ALB target group"
  value       = module.alb.target_group_arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

# EC2 outputs
output "primary_instance_id" {
  description = "ID of the primary EC2 instance"
  value       = module.primary_ec2.instance_ids[0]
}

output "primary_instance_ids" {
  description = "List of primary EC2 instance IDs"
  value       = module.primary_ec2.instance_ids
}

output "primary_alb_arn" {
  description = "ARN of the primary ALB"
  value       = module.alb.alb_arn
}

output "primary_target_group_arn" {
  description = "ARN of the primary target group"
  value       = module.alb.target_group_arn
}

output "primary_rds_id" {
  description = "ID of the primary RDS instance"
  value       = module.primary_rds.primary_id
}

output "primary_rds_arn" {
  description = "ARN of the primary RDS instance"
  value       = module.primary_rds.primary_instance_arn
}

output "notification_topic_arn" {
  description = "ARN of the SNS notification topic"
  value       = module.sns.topic_arn
}