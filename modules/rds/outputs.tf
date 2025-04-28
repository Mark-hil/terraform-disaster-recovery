output "primary_db_instance_id" {
  description = "ID of the primary RDS instance"
  value       = var.create_replica ? null : aws_db_instance.primary[0].id
}

output "primary_db_instance_arn" {
  description = "ARN of the primary RDS instance"
  value       = var.create_replica ? "" : aws_db_instance.primary[0].arn
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].endpoint : aws_db_instance.primary[0].endpoint
}

# output "rds_endpoint" {
#   description = "The connection endpoint for the RDS instance"
#   value       = var.create_replica ? aws_db_instance.dr_replica[0].endpoint : aws_db_instance.primary[0].endpoint
# }

output "primary_id" {
  description = "The ID of the primary RDS instance"
  value       = var.create_replica ? null : aws_db_instance.primary[0].id
}

output "dr_id" {
  description = "The ID of the DR RDS instance"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].id : null
}

# Debug outputs
output "debug_monitoring_role_arn" {
  description = "Debug: The monitoring role ARN being used"
  value       = var.monitoring_role_arn
}

output "debug_monitoring_interval" {
  description = "Debug: The monitoring interval being used"
  value       = var.monitoring_interval
}

output "rds_username" {
  description = "Username of the RDS instance"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].username : aws_db_instance.primary[0].username
}

output "rds_database_name" {
  description = "Database name"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].db_name : aws_db_instance.primary[0].db_name
}

output "dr_replica_db_instance_id" {
  description = "ID of the DR replica RDS instance"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].id : null
}

output "dr_replica_db_instance_arn" {
  description = "ARN of the DR replica RDS instance"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].arn : null
}

output "dr_replica_db_endpoint" {
  description = "Endpoint of the DR replica RDS instance"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].endpoint : null
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.primary.name
}

output "parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.primary.name
}

output "primary_instance_arn" {
  description = "ARN of the primary RDS instance"
  value       = var.create_replica ? "" : aws_db_instance.primary[0].arn
}

output "db_endpoint" {
  description = "The endpoint of the database"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].endpoint : aws_db_instance.primary[0].endpoint
}

output "replica_instance_id" {
  description = "ID of the read replica instance"
  value       = var.create_replica ? aws_db_instance.dr_replica[0].id : ""
}

output "primary_instance_id" {
  description = "ID of the primary instance"
  value       = var.create_replica ? "" : aws_db_instance.primary[0].id
}