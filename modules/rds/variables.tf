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
  description = "ARN of the IAM role for RDS monitoring"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "storage_size" {
  description = "RDS storage size"
  type        = number
  default     = 20
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