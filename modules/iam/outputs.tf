# Output role ARNs for S3 replication
# output "s3_replication_role_arn" {
#   description = "ARN of the S3 replication role"
#   value       = var.environment == "primary" ? aws_iam_role.s3_replication[0].arn : ""
# }
# output "s3_replication_role_name" {
#   description = "Name of the S3 replication role"
#   value       = var.environment == "primary" ? aws_iam_role.s3_replication[0].name : ""
# }
# output "ec2_instance_profile_name" {
#   value = aws_iam_instance_profile.ec2.name
#   description = "The name of the EC2 instance profile"
# }

# output "rds_monitoring_role_arn" {
#   description = "ARN of the RDS monitoring role"
#   value       = var.create_roles ? aws_iam_role.rds_monitoring[0].arn : null
# }

# output "lambda_failover_role_arn" {
#   description = "ARN of the Lambda failover role"
#   value       = var.create_roles ? aws_iam_role.lambda_failover[0].arn : null
# }

# output "ami_replication_lambda_role_arn" {
#   description = "ARN of the AMI replication Lambda role"
#   value       = var.create_roles ? aws_iam_role.ami_replication_lambda[0].arn : null
# }

# output "s3_replication_role_arn" {
#   description = "ARN of the S3 replication role"
#   value       = var.environment == "primary" && var.create_roles ? aws_iam_role.s3_replication[0].arn : null
# }

# output "ec2_instance_profile_name" {
#   description = "Name of the EC2 instance profile"
#   value       = var.create_roles ? aws_iam_instance_profile.ec2[0].name : null
# }

# output "s3_replication_role_arn" {
#   value = aws_iam_role.roles["ami_replication"].arn
# }
