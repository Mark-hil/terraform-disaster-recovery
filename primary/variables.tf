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
  default     = "postgres"
}

variable "DB_HOST" {
  description = "Hostname for RDS instance"
  type        = string
  default     = "" # Will be set by RDS module
}

variable "instance_class" {
  description = "Instance class for RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 100
}

variable "engine_version" {
  description = "Engine version for RDS"
  type        = string
  default     = "8.0"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "primary_region" {
  description = "AWS region for primary infrastructure"
  type        = string
}

variable "dr_region" {
  description = "AWS region for DR resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "ssh_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access instances via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
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

variable "db_password" {
  description = "Password for RDS instance"
  type        = string
  sensitive   = true
  default     = "postgres"
}

variable "dr_instance_id" {
  description = "ID of the DR instance"
  type        = string
  default     = ""
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
  default     = []
}

variable "internal_alb" {
  description = "Whether the ALB is internal"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ARN of the certificate for ALB"
  type        = string
  default     = ""
}

variable "dr_alb_arn" {
  description = "ARN of the DR ALB"
  type        = string
  default     = "" # Will be set by DR module
}

variable "dr_target_group_arn" {
  description = "ARN of the DR target group"
  type        = string
  default     = "" # Will be set by DR module
}

variable "aws_region" {
  description = "AWS region for primary infrastructure"
  type        = string
  default     = ""
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days to keep noncurrent versions before deletion"
  type        = number
  default     = 30
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

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}