output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.dr.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.dr.dns_name
}

output "primary_target_group_arn" {
  description = "ARN of the primary RDS target group"
  value       = aws_lb_target_group.primary.arn
}

output "dr_target_group_arn" {
  description = "ARN of the DR RDS target group"
  value       = aws_lb_target_group.dr.arn
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.dr.arn
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}
