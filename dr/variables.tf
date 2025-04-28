variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "DB_PASSWORD" {
  description = "Password for RDS instance"
  type        = string
  sensitive   = true
  default     = "postgres"
}

variable "DB_USER" {
  description = "Username for RDS instance"
  type        = string
}

variable "DB_HOST" {
  description = "Hostname for RDS instance"
  type        = string
  default     = "" # Will be set by RDS module
}

variable "DB_NAME" {
  description = "Name of the database"
  type        = string
  default     = "chat_db"
}

variable "primary_region" {
  description = "AWS region for primary infrastructure"
  type        = string
}

variable "dr_region" {
  description = "AWS region for DR resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption"
  type        = string
  default     = null
}

variable "dr_kms_key_arn" {
  description = "ARN of KMS key for DR RDS encryption"
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days to keep noncurrent versions before deletion"
  type        = number
  default     = 30
}

variable "primary_s3_arn" {
  description = "ARN of primary S3 bucket"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for DR infrastructure"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "primary_instance_id" {
  description = "ID of the primary EC2 instance"
  type        = string
}

variable "primary_instance_ids" {
  description = "List of primary EC2 instance IDs"
  type        = list(string)
}

variable "primary_alb_arn" {
  description = "ARN of the primary ALB"
  type        = string
}

variable "primary_target_group_arn" {
  description = "ARN of the primary target group"
  type        = string
}

variable "primary_rds_id" {
  description = "ID of the primary RDS instance"
  type        = string
}

variable "primary_rds_arn" {
  description = "ARN of the primary RDS instance to create read replica from"
  type        = string
}

variable "notification_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}