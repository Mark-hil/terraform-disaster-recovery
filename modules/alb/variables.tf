variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
}

variable "primary_rds_address" {
  description = "IP address or DNS name of the primary RDS instance"
  type        = string
}

variable "dr_rds_address" {
  description = "IP address or DNS name of the DR RDS instance"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
