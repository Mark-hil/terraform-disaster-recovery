variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "primary_region" {
  description = "AWS region for primary infrastructure"
  type        = string
}

variable "dr_region" {
  description = "AWS region for disaster recovery infrastructure"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of KMS key for primary region encryption"
  type        = string
  default     = null
}

variable "dr_kms_key_arn" {
  description = "ARN of KMS key for DR region encryption"
  type        = string
  default     = null
}

# Network configuration
variable "primary_vpc_cidr" {
  description = "CIDR block for primary VPC"
  type        = string
}

variable "dr_vpc_cidr" {
  description = "CIDR block for DR VPC"
  type        = string
}

variable "primary_azs" {
  description = "List of availability zones in primary region"
  type        = list(string)
}

variable "dr_azs" {
  description = "List of availability zones in DR region"
  type        = list(string)
}

variable "primary_private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks for primary VPC"
  type        = list(string)
}

variable "primary_public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks for primary VPC"
  type        = list(string)
}

variable "dr_private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks for DR VPC"
  type        = list(string)
}

variable "dr_public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks for DR VPC"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
