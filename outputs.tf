# Primary region outputs
output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = module.primary.vpc_id
}

output "primary_public_subnet_ids" {
  description = "Primary public subnet IDs"
  value       = module.primary.public_subnet_ids
}

output "primary_private_subnet_ids" {
  description = "Primary private subnet IDs"
  value       = module.primary.private_subnet_ids
}

output "primary_rds_endpoint" {
  description = "Primary RDS endpoint"
  value       = module.primary.rds_endpoint
}

output "primary_s3_bucket_arn" {
  description = "Primary S3 bucket ARN"
  value       = module.primary.s3_bucket_arn
}

# DR region outputs
output "dr_vpc_id" {
  description = "DR VPC ID"
  value       = module.dr.vpc_id
}

output "dr_public_subnet_ids" {
  description = "DR public subnet IDs"
  value       = module.dr.public_subnet_ids
}

output "dr_private_subnet_ids" {
  description = "DR private subnet IDs"
  value       = module.dr.private_subnet_ids
}

output "dr_security_group_id" {
  description = "DR security group ID"
  value       = module.dr.security_group_id
}
