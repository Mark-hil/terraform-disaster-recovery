variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "DB_NAME" {
  description = "Name of the database"
  type        = string
}

variable "DB_USER" {
  description = "Username for the database"
  type        = string
}

variable "DB_PASSWORD" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs that can access RDS"
  type        = list(string)
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = string
}

variable "parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = "postgres16"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = false
}

variable "primary_instance_arn" {
  description = "ARN of the primary RDS instance to create read replica from"
  type        = string
  default     = ""
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot when destroying the database"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "The name of the final snapshot when destroying the database"
  type        = string
  default     = null
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected. Set to 0 to disable."
  type        = number
  default     = 0  # Disable monitoring by default
}

# variable "monitoring_role_arn" {
#   description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
#   type        = string
#   default     = null  # Will be provided when monitoring is enabled
# }