variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "alarm_topic_arns" {
  description = "List of SNS topic ARNs for alarms"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "primary_region" {
  description = "Primary region for resources"
  type        = string
  default     = null
}

variable "dr_region" {
  description = "DR region for resources"
  type        = string
  default     = null
}

variable "dr_rds_id" {
  description = "ID of the DR RDS instance"
  type        = string
  default     = null
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = null
}
