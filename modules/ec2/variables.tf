variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "instance_state" {
  description = "Desired state of the instances (running or stopped)"
  type        = string
  default     = "running"
  validation {
    condition     = contains(["running", "stopped"], var.instance_state)
    error_message = "Instance state must be either 'running' or 'stopped'."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to instances"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile to attach to instances"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "dr_ami_parameter" {
  description = "SSM parameter name for DR AMI"
  type        = string
  default     = ""
}

variable "frontend_image" {
  description = "Docker image for the frontend container"
  type        = string
  default     = "markhill97/chat-frontend:1.0"
}

variable "backend_image" {
  description = "Docker image for the backend container"
  type        = string
  default     = "markhill97/chat-backend:1.0"
}

variable "frontend_port" {
  description = "Port for the frontend container"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port for backend service"
  type        = number
  default     = 8000
}

variable "DB_HOST" {
  description = "Database host"
  type        = string
}

variable "DB_NAME" {
  description = "Database name"
  type        = string
}

variable "DB_USER" {
  description = "Database username"
  type        = string
}

variable "DB_PASSWORD" {
  description = "Database password"
  type        = string
  sensitive   = true
}