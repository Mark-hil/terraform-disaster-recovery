variable "environment" {
  description = "Environment name"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
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
  description = "ARN of the IAM role for RDS monitoring"
  type        = string
}

variable "parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = "mysql8.0"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}