# Lambda Function Module for DR Failover

# Archive the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function/index.py"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-dr-failover-lambda-role"

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

  tags = {
    Name = "${var.environment}-dr-failover-lambda-role"
  }
}

# IAM policy for the Lambda function
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.environment}-dr-failover-lambda-policy"
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
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:StartInstances",
          "ec2:StopInstances"
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

# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.dr_failover.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.environment}-dr-failover-lambda-logs"
  }
}

# Lambda Function
resource "aws_lambda_function" "dr_failover" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-dr-failover"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.10"
  timeout         = 300

  environment {
    variables = {
      PRIMARY_EC2_IDS        = join(",", var.primary_ec2_ids)
      DR_EC2_IDS             = join(",", var.dr_ec2_ids)
      ALB_ARN                = var.primary_alb_arn
      PRIMARY_TARGET_GROUP_ARN = var.primary_target_group_arn
      DR_TARGET_GROUP_ARN     = var.dr_target_group_arn
      PRIMARY_REGION         = var.primary_region
      DR_REGION             = var.dr_region
      PRIMARY_RDS_ID        = var.primary_rds_id
      DR_RDS_ID             = var.dr_rds_identifier
    }
  }

  tags = {
    Name = "${var.environment}-dr-failover"
  }
}

# SNS Topic for alarms
resource "aws_sns_topic" "failover_alarm" {
  name = "${var.environment}-dr-failover-alarm"

  tags = {
    Name = "${var.environment}-dr-failover-alarm"
  }
}

# SNS Topic subscription to Lambda
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.failover_alarm.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.dr_failover.arn
}

# Lambda permission to allow SNS
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.failover_alarm.arn
}

# CloudWatch Alarm for EC2 Status
resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "${var.environment}-primary-ec2-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 status"
  alarm_actions       = [aws_sns_topic.failover_alarm.arn]

  dimensions = {
    InstanceId = var.primary_ec2_ids[0]
  }
}

# CloudWatch Alarm for RDS Status
resource "aws_cloudwatch_metric_alarm" "rds_status" {
  alarm_name          = "${var.environment}-primary-rds-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "90"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.failover_alarm.arn]

  dimensions = {
    DBInstanceIdentifier = var.dr_rds_identifier
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
