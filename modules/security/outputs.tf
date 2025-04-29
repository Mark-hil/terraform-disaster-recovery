output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "ID of the application security group"
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "ID of the RDS security group"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ID of the ALB security group"
}
