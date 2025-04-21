variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_password" {
  description = "Password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Username for the RDS instance"
  type        = string
}

variable "db_host" {
  description = "Hostname for the RDS instance"
  type        = string
}

variable "primary_region" {
  description = "AWS region for primary resources"
  type        = string
}

variable "dr_region" {
  description = "AWS region for DR resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for DR VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones in DR region"
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
  description = "ARN of KMS key for RDS encryption"
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
  description = "AWS region for DR resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}