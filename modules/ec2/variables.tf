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

variable "docker_image" {
  description = "Docker image to run on the instances"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port that the Docker container listens on"
  type        = number
  default     = 80
}

variable "host_port" {
  description = "Port on the host to map to the container"
  type        = number
  default     = 80
}