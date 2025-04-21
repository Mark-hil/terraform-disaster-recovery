output "primary_db_instance_id" {
  description = "ID of the primary RDS instance"
  value       = aws_db_instance.primary.id
}

output "primary_db_instance_arn" {
  description = "ARN of the primary RDS instance"
  value       = aws_db_instance.primary.arn
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.primary.port
}

output "rds_username" {
  description = "RDS username"
  value       = aws_db_instance.primary.username
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.primary.db_name
}

output "dr_replica_db_instance_id" {
  description = "ID of the DR replica RDS instance"
  value       = aws_db_instance.dr_replica.id
}

output "dr_replica_db_instance_arn" {
  description = "ARN of the DR replica RDS instance"
  value       = aws_db_instance.dr_replica.arn
}

output "dr_replica_db_endpoint" {
  description = "Endpoint of the DR replica RDS instance"
  value       = aws_db_instance.dr_replica.endpoint
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.primary.name
}

output "parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.primary.name
}