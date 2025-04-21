variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "primary_region" {
  description = "AWS region where the primary infrastructure is deployed"
  type        = string
}

variable "dr_region" {
  description = "AWS region where the DR infrastructure is deployed"
  type        = string
}

variable "primary_rds_id" {
  description = "ID of the primary RDS instance"
  type        = string
}

variable "dr_rds_id" {
  description = "ID of the DR RDS instance (read replica)"
  type        = string
}

variable "primary_target_group_arn" {
  description = "ARN of the primary RDS target group"
  type        = string
}

variable "dr_target_group_arn" {
  description = "ARN of the DR RDS target group"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  type        = string
}

variable "dr_bucket_name" {
  description = "Name of the DR S3 bucket"
  type        = string
}

variable "health_check_schedule" {
  description = "CloudWatch Events schedule expression for health checks"
  type        = string
  default     = "rate(1 minute)"
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda function logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
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
