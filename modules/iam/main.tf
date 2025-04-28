terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_region" "current" {}

locals {
  rds_monitoring_role_name       = "${var.environment}-rds-monitoring-role"
  ec2_role_name                  = "${var.environment}-ec2-role"
  s3_replication_role_name       = "${var.environment}-s3-replication-role"
  ami_replication_lambda_role_name = "${var.environment}-ami-replication-lambda-role"
  lambda_failover_role_name      = "${var.environment}-lambda-failover-role"
}

# Create IAM roles only in primary region
resource "aws_iam_role" "rds_monitoring" {
  count = var.create_roles ? 1 : 0
  name  = local.rds_monitoring_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = local.rds_monitoring_role_name
  })
}

# Attach the RDS monitoring policy
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.create_roles ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role" "ec2" {
  count = var.create_roles ? 1 : 0
  name  = local.ec2_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "lambda_failover" {
  count = var.create_roles ? 1 : 0
  name  = local.lambda_failover_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "ami_replication_lambda" {
  count = var.create_roles ? 1 : 0
  name  = local.ami_replication_lambda_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "s3_replication" {
  count = var.environment == "primary" && var.create_roles ? 1 : 0
  name  = local.s3_replication_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Create EC2 instance profile only in primary region
resource "aws_iam_instance_profile" "ec2" {
  count    = var.create_roles ? 1 : 0
  name     = local.ec2_role_name
  role     = aws_iam_role.ec2[0].name
}

# Add S3 bucket ARNs variable
variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs for replication"
  type        = list(string)
  default     = []
}

# Attach policies to roles
# resource "aws_iam_role_policy_attachment" "rds_monitoring" {
#   count      = var.create_roles ? 1 : 0
#   role       = aws_iam_role.rds_monitoring[0].name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
# }

resource "aws_iam_role_policy" "ec2_policy" {
  count    = var.create_roles ? 1 : 0
  name     = "${var.environment}-ec2-policy"
  role     = aws_iam_role.ec2[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ], var.additional_ec2_policy_statements)
  })
}

resource "aws_iam_role_policy" "lambda_failover" {
  count    = var.create_roles ? 1 : 0
  name     = "${var.environment}-lambda-failover-policy"
  role     = aws_iam_role.lambda_failover[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:PromoteReadReplica"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ami_replication_lambda" {
  count    = var.create_roles ? 1 : 0
  name     = "${var.environment}-ami-replication-lambda-policy"
  role     = aws_iam_role.ami_replication_lambda[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:CreateImage",
          "ec2:CopyImage",
          "ec2:DeregisterImage",
          "ec2:DescribeImages",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_replication" {
  provider = aws
  name     = "${var.environment}-s3-replication-policy"
  count    = var.environment == "primary" && var.create_roles ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arns
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [for arn in var.s3_bucket_arns : "${arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = [for arn in var.s3_bucket_arns : "${arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  count    = var.environment == "primary" && var.create_roles ? 1 : 0
  name     = "${var.environment}-s3-replication-policy"
  role     = aws_iam_role.s3_replication[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arns
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [for arn in var.s3_bucket_arns : "${arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = [for arn in var.s3_bucket_arns : "${arn}/*"]
      }
    ]
  })
}

# Output role ARNs
# Outputs for role ARNs and instance profile
output "ec2_role_arn" {
  description = "ARN of the EC2 role"
  value       = var.create_roles ? aws_iam_role.ec2[0].arn : null
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS monitoring role"
  value       = var.create_roles ? aws_iam_role.rds_monitoring[0].arn : null
}

output "lambda_failover_role_arn" {
  description = "ARN of the Lambda failover role"
  value       = var.create_roles ? aws_iam_role.lambda_failover[0].arn : null
}

output "ami_replication_lambda_role_arn" {
  description = "ARN of the AMI replication Lambda role"
  value       = var.create_roles ? aws_iam_role.ami_replication_lambda[0].arn : null
}

output "s3_replication_role_arn" {
  description = "ARN of the S3 replication role"
  value       = var.environment == "primary" && var.create_roles ? aws_iam_role.s3_replication[0].arn : null
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = var.create_roles ? aws_iam_instance_profile.ec2[0].name : null
}