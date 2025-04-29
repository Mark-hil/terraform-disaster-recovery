variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "name" {
  description = "Name for the ALB and related resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to attach to the target group"
  type        = list(string)
}

variable "target_type" {
  description = "Type of target that you must specify when registering targets with this target group"
  type        = string
  default     = "instance"
}

variable "frontend_port" {
  description = "Port for the frontend application"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port for the backend application"
  type        = number
  default     = 8000
}

variable "health_check_path_frontend" {
  description = "Health check path for the frontend application"
  type        = string
  default     = "/"
}

variable "health_check_path_backend" {
  description = "Health check path for the backend application"
  type        = string
  default     = "/admin/"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "log_bucket" {
  description = "Name of the S3 bucket for ALB access logs"
  type        = string
  default     = ""
}
