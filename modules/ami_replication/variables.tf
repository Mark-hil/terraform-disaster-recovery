variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "source_instance_id" {
  description = "ID of the source EC2 instance in primary region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "env_vars" {
  description = "Environment variables to store in SSM Parameter Store"
  type        = string
  sensitive   = true
}

variable "dr_region" {
  description = "DR AWS region"
  type        = string
}

variable "primary_instance_id" {
  description = "ID of the primary EC2 instance"
  type        = string
}
