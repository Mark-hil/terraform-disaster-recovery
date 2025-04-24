# VPC Configuration
vpc_cidr = "10.1.0.0/16"
availability_zones = [
  "us-west-1a",
  "us-west-1b"
]
private_subnets = [
  "10.1.1.0/24",
  "10.1.2.0/24"
]
public_subnets = [
  "10.1.101.0/24",
  "10.1.102.0/24"
]

# RDS Configuration
DB_NAME = "chat_db"
DB_USER = "postgres"
DB_PASSWORD = "postgres"
DB_HOST = "" # This will be populated by RDS endpoint
instance_class = "db.t3.micro"
allocated_storage = 100
engine_version = "8.0"

# S3 Configuration
# bucket_name = "aws-dr-project-replica"
noncurrent_version_expiration_days = 30

# KMS Configuration
# These will be replaced by the actual KMS keys created by terraform
kms_key_arn = ""
dr_kms_key_arn = ""

# Common Settings
environment = "prod"
dr_region = "us-west-1"
primary_region = "eu-west-1"
project_name = "aws-dr-project"

# Lambda Failover Settings
# primary_region = "eu-west-1"
# health_check_schedule = "rate(1 minute)"
# log_retention_days = 30
# failover_threshold = 3

# DNS Settings
# ALB Configuration
# alb_certificate_arn = ""
# internal_alb = true
# dns_name = "db.example.com"

# Monitoring Settings
# notification_topic_name = "dr-failover-notifications"

# Tags
tags = {
  Project     = "aws-dr-project"
  Environment = "prod"
  Region      = "DR"
  Terraform   = "true"
  Owner       = "infrastructure-team"
}