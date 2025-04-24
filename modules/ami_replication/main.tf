# IAM role for Lambda
resource "aws_iam_role" "ami_replication_lambda" {
  provider = aws.dr
  name = "${var.environment}-${var.project_name}-ami-replication-lambda-role-${formatdate("YYYYMMDDHHmmss", timestamp())}"

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
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "ami_replication_lambda" {
  provider = aws.dr
  name = "${var.environment}-ami-replication-lambda-policy"
  role = aws_iam_role.ami_replication_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateImage",
          "ec2:CopyImage",
          "ec2:DeregisterImage",
          "ec2:DescribeImages",
          "ec2:CreateTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/dr/${var.environment}/${var.project_name}/*"
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

# Lambda function for AMI replication
resource "aws_lambda_function" "ami_replication" {
  provider = aws.dr
  filename         = "${path.module}/lambda_function.zip"
  function_name = "${var.environment}-${var.project_name}-ami-replication-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  role            = aws_iam_role.ami_replication_lambda.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      PRIMARY_REGION = var.primary_region
      DR_REGION = data.aws_region.current.name
      PRIMARY_INSTANCE_ID = var.source_instance_id
      ENVIRONMENT = var.environment
      PROJECT_NAME = var.project_name
    }
  }


}

# CloudWatch Event Rule for daily AMI replication
resource "aws_cloudwatch_event_rule" "daily_ami_replication" {
  provider = aws.dr
  name                = "${var.environment}-${var.project_name}-daily-ami-replication"
  description         = "Triggers AMI replication Lambda function daily"
  schedule_expression = "cron(0 1 * * ? *)"  # Run at 1 AM UTC daily
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "ami_replication_lambda" {
  provider = aws.dr
  rule      = aws_cloudwatch_event_rule.daily_ami_replication.name
  target_id = "AMIReplicationLambda"
  arn       = aws_lambda_function.ami_replication.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  provider = aws.dr
  statement_id  = "AllowCloudWatchEventsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_replication.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_ami_replication.arn
}

# Get current region
data "aws_region" "current" {
  provider = aws.dr
}

# SSM Parameter to store latest AMI ID
resource "aws_ssm_parameter" "latest_ami" {
  provider = aws.dr
  name  = "/dr/${var.environment}/${var.project_name}/latest-ami"
  type  = "String"
  value = jsonencode({
    id   = ""
    name = ""
  })
  overwrite = true

  lifecycle {
    ignore_changes = [value]
  }
}

# SSM Parameter to store environment variables
resource "aws_ssm_parameter" "env_vars" {
  provider = aws.dr
  name  = "/dr/${var.environment}/${var.project_name}/env-vars"
  type  = "String"
  value = jsonencode({
    primary_region = var.primary_region
    dr_region     = var.dr_region
    instance_id   = var.primary_instance_id
  })
  overwrite = true

  tags = {
    Name = "${var.environment}-${var.project_name}-env-vars"
  }
}

# Output the SSM Parameter name for the latest AMI
output "latest_ami_parameter" {
  description = "SSM Parameter name containing the latest DR AMI ID"
  value       = aws_ssm_parameter.latest_ami.name
}
