# Lambda Function Module for DR Failover

# Archive the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-dr-failover-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for the Lambda function
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-dr-failover-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:RebootDBInstance",
          "rds:PromoteReadReplica"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketReplication",
          "s3:GetReplicationConfiguration"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-dr-failover"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda Function
resource "aws_lambda_function" "dr_failover" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-dr-failover"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = 300
  memory_size      = 256

  environment {
    variables = {
      PRIMARY_REGION          = var.primary_region
      DR_REGION              = var.dr_region
      PRIMARY_RDS_ID         = var.primary_rds_id
      DR_RDS_ID              = var.dr_rds_id
      PRIMARY_TARGET_GROUP_ARN = var.primary_target_group_arn
      DR_TARGET_GROUP_ARN    = var.dr_target_group_arn
      ALB_ARN               = var.alb_arn
      PRIMARY_BUCKET        = var.primary_bucket_name
      DR_BUCKET             = var.dr_bucket_name
    }
  }

  tags = var.tags
}

# CloudWatch Event Rule for automated health checks
resource "aws_cloudwatch_event_rule" "health_check" {
  name                = "${var.project_name}-dr-health-check"
  description         = "Periodic health check of primary region resources"
  schedule_expression = var.health_check_schedule

  tags = var.tags
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.health_check.name
  target_id = "${var.project_name}-dr-failover-lambda"
  arn       = aws_lambda_function.dr_failover.arn
}

# Lambda permission to allow CloudWatch Events
resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_check.arn
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
