variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "primary_region" {
  description = "Primary region where the source AMI exists"
  type        = string
}

variable "dr_region" {
  description = "DR region where the AMI should be replicated"
  type        = string
}

variable "primary_ec2_id" {
  description = "ID of the primary EC2 instance"
  type        = string
}

variable "schedule_expression" {
  description = "Schedule expression for AMI replication (e.g., cron(0 1 * * ? *))"
  type        = string
  default     = "cron(0 1 * * ? *)"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
