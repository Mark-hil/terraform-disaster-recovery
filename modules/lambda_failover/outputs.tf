output "lambda_function_arn" {
  description = "ARN of the DR failover Lambda function"
  value       = aws_lambda_function.dr_failover.arn
}

output "lambda_function_name" {
  description = "Name of the DR failover Lambda function"
  value       = aws_lambda_function.dr_failover.function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "health_check_rule_arn" {
  description = "ARN of the CloudWatch Events rule for health checks"
  value       = aws_cloudwatch_event_rule.health_check.arn
}
