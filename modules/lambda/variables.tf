variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "primary_instance_id" {
  description = "ID of the primary EC2 instance"
  type        = string
}

variable "dr_instance_id" {
  description = "ID of the DR EC2 instance"
  type        = string
}

variable "primary_rds_arn" {
  description = "ARN of the primary RDS instance"
  type        = string
}

variable "dr_rds_arn" {
  description = "ARN of the DR RDS instance"
  type        = string
}

variable "primary_target_group_arn" {
  description = "ARN of the primary ALB target group"
  type        = string
}

variable "dr_target_group_arn" {
  description = "ARN of the DR ALB target group"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
