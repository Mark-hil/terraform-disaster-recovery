# Project Settings
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-dr-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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
  default     = ""  # Will be set by RDS module
}

variable "DB_NAME" {
  description = "Name of the database"
  type        = string
  default     = "chat_db"
}

# Region Settings
variable "primary_region" {
  description = "AWS region for primary infrastructure"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "AWS region for disaster recovery infrastructure"
  type        = string
  default     = "us-east-1"
}

# Network Settings
variable "primary_vpc_cidr" {
  description = "CIDR block for primary VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dr_vpc_cidr" {
  description = "CIDR block for DR VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "primary_azs" {
  description = "List of availability zones in primary region"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "dr_azs" {
  description = "List of availability zones in DR region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "primary_private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks for primary VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "primary_public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks for primary VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "dr_private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks for DR VPC"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "dr_public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks for DR VPC"
  type        = list(string)
  default     = ["10.1.101.0/24", "10.1.102.0/24"]
}

# RDS Settings
variable "rds_instance_class" {
  description = "Instance class for RDS instances"
  type        = string
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for RDS instances"
  type        = number
  default     = 20
}

# KMS Settings
variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption (optional)"
  type        = string
  default     = ""
}

variable "dr_kms_key_arn" {
  description = "ARN of the KMS key for DR encryption (optional)"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "aws-dr-project"
    Owner       = "infrastructure-team"
    Terraform   = "true"
  }
}
