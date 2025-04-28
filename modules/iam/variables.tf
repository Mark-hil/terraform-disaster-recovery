variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_roles" {
  description = "Whether to create new roles or use existing ones"
  type        = bool
  default     = true
}

variable "additional_ec2_policy_statements" {
  description = "Additional policy statements to add to the EC2 role"
  type = list(object({
    Effect    = string
    Action    = list(string)
    Resource  = string
  }))
  default = []
}

variable "source_bucket_arn" {
  description = "ARN of the source S3 bucket for replication"
  type        = string
  default     = ""
}

variable "destination_bucket_arn" {
  description = "ARN of the destination S3 bucket for replication"
  type        = string
  default     = ""
}
