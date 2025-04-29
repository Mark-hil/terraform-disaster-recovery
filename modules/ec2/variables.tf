variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs where EC2 instances will be launched"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "instance_state" {
  description = "Desired state of the instance (running or stopped)"
  type        = string
  default     = "running"
  validation {
    condition     = contains(["running", "stopped"], var.instance_state)
    error_message = "Instance state must be either 'running' or 'stopped'."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to EC2 instances"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile to attach to EC2 instances"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "ami_id" {
  description = "AMI ID to use for the instances. If not provided, latest Amazon Linux 2 will be used."
  type        = string
  default     = ""
}

variable "dr_ami_parameter" {
  description = "SSM parameter name for DR AMI"
  type        = string
  default     = ""
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