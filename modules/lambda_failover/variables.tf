variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
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
  description = "AWS region for DR infrastructure"
  type        = string
}

variable "primary_ec2_ids" {
  description = "List of primary EC2 instance IDs"
  type        = list(string)
}

variable "dr_ec2_ids" {
  description = "List of DR EC2 instance IDs"
  type        = list(string)
}

variable "dr_rds_identifier" {
  description = "Identifier of the DR RDS instance"
  type        = string
}

variable "primary_alb_arn" {
  description = "ARN of the primary ALB"
  type        = string
}

variable "dr_alb_arn" {
  description = "ARN of the DR ALB"
  type        = string
}

variable "primary_target_group_arn" {
  description = "ARN of the primary target group"
  type        = string
}

variable "dr_target_group_arn" {
  description = "ARN of the DR target group"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda logs"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "health_check_schedule" {
  description = "CloudWatch Events schedule expression for health checks"
  type        = string
  default     = "rate(1 minute)"
}

variable "failover_threshold" {
  description = "Number of consecutive health check failures before triggering failover"
  type        = number
  default     = 3
}

variable "notification_topic_arn" {
  description = "ARN of the SNS topic for failover notifications"
  type        = string
  default     = ""
}

variable "primary_rds_id" {
  description = "ID of the primary RDS instance"
  type        = string
}
