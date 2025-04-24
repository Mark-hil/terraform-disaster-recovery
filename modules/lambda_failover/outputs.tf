output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.dr_failover.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.dr_failover.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.failover_alarm.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}
