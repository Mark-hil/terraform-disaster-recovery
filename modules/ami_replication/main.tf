# Lambda Function Module for AMI Replication

data "aws_region" "current" {}

locals {
  function_name = "${var.environment}-ami-replication-lambda"
  resource_tags = merge(
    var.tags,
    {
      Name = local.function_name
      Function = "AMI Replication"
    }
  )
}

# CloudWatch Log Group for Lambda logs
# resource "aws_cloudwatch_log_group" "lambda_logs" {
#   provider          = aws.dr
#   name              = "/aws/lambda/${local.function_name}"
#   retention_in_days = var.log_retention_days
# }

# Lambda function for AMI replication
# resource "aws_lambda_function" "ami_replication" {
#   provider         = aws.dr
#   filename         = "${path.module}/lambda_function/ami_replication.zip"
#   function_name    = local.function_name
#   role            = var.lambda_role_arn
#   handler         = "ami_replication.lambda_handler"
#   source_code_hash = filebase64sha256("${path.module}/lambda_function/ami_replication.zip")
#   runtime         = "python3.9"
#   timeout         = 300

#   environment {
#     variables = {
#       PRIMARY_REGION  = var.primary_region
#       DR_REGION       = var.dr_region
#       PRIMARY_EC2_ID  = var.primary_ec2_id
#       PROJECT_NAME    = var.project_name
#       ENVIRONMENT     = var.environment
#     }
#   }
# }

# CloudWatch Event Rule to trigger Lambda function
# resource "aws_cloudwatch_event_rule" "ami_replication" {
#   provider            = aws.dr
#   name                = "${var.environment}-ami-replication"
#   description         = "Trigger AMI replication Lambda function"
#   schedule_expression = var.schedule_expression
# }

# # CloudWatch Event Target
# resource "aws_cloudwatch_event_target" "ami_replication" {
#   provider  = aws.dr
#   rule      = aws_cloudwatch_event_rule.ami_replication.name
#   target_id = "AMIReplicationLambda"
#   arn       = aws_lambda_function.ami_replication.arn
# }

# # Lambda permission to allow CloudWatch Events to invoke the function
# resource "aws_lambda_permission" "allow_cloudwatch" {
#   provider      = aws.dr
#   statement_id  = "AllowCloudWatchInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.ami_replication.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.ami_replication.arn
# }
