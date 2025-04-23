variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-dr-project"
}

variable "primary_region" {
  description = "AWS region for primary infrastructure"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "AWS region for DR infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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

variable "vpc_cidr" {
  description = "CIDR block for primary VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones in primary region"
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

variable "noncurrent_version_expiration_days" {
  description = "Number of days to keep noncurrent versions before deletion"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "ARN of KMS key for RDS encryption"
  type        = string
  default     = null
}

variable "dr_bucket_arn" {
  description = "ARN of DR S3 bucket"
  type        = string
  default     = ""
}

variable "dr_rds_id" {
  description = "ID of DR RDS instance"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Name of the Lambda function for failover"
  type        = string
  default     = ""
}

variable "dr_kms_key_arn" {
  description = "ARN of KMS key for DR RDS encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "aws-dr-project"
  }
}

# DR module outputs
variable "dr_instance_id" {
  description = "ID of the DR EC2 instance"
  type        = string
  default     = ""
}

variable "dr_alb_arn" {
  description = "ARN of the DR ALB"
  type        = string
  default     = ""
}

variable "dr_target_group_arn" {
  description = "ARN of the DR ALB target group"
  type        = string
  default     = ""
}