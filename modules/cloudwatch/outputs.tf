output "sns_topic_arn" {
  description = "ARN of the SNS topic for DR alerts"
  value       = aws_sns_topic.dr_alerts.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.dr_dashboard.dashboard_name
}

output "ec2_status_alarm_arn" {
  description = "ARN of the EC2 status alarm"
  value       = aws_cloudwatch_metric_alarm.primary_ec2_status.arn
}

output "rds_status_alarm_arn" {
  description = "ARN of the RDS status alarm"
  value       = aws_cloudwatch_metric_alarm.primary_rds_status.arn
}

output "rds_cpu_alarm_arn" {
  description = "ARN of the RDS CPU alarm"
  value       = aws_cloudwatch_metric_alarm.rds_cpu.arn
}

output "rds_storage_alarm_arn" {
  description = "ARN of the RDS storage alarm"
  value       = aws_cloudwatch_metric_alarm.rds_storage.arn
}