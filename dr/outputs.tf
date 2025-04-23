output "vpc_id" {
  description = "ID of the DR VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets in DR VPC"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets in DR VPC"
  value       = module.vpc.public_subnet_ids
}

# RDS outputs are now provided by the primary module since we're using cross-region replication

# Temporarily commented out
/*
output "s3_bucket_id" {
  description = "ID of the DR S3 bucket"
  value       = module.dr_s3.replica_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the DR S3 bucket"
  value       = module.dr_s3.replica_bucket_arn
}
*/

output "security_group_id" {
  description = "ID of the DR security group"
  value       = module.security_group.app_security_group_id
}

# EC2 outputs
output "dr_instance_id" {
  description = "ID of the DR EC2 instance"
  value       = module.dr_ec2.instance_ids[0]
}

# ALB outputs
output "dr_target_group_arn" {
  description = "ARN of the DR ALB target group"
  value       = module.alb.target_group_arn
}

output "dr_alb_arn" {
  description = "ARN of the DR ALB"
  value       = module.alb.alb_arn
}