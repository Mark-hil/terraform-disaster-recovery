# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = [
  "eu-west-1a",
  "eu-west-1b"
]
private_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]
public_subnets = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]

# RDS Configuration
DB_NAME                = "chat_db"
DB_USER                = "postgres"
DB_PASSWORD            = "postgres"
DB_HOST                = "" # This will be populated by RDS endpoint
instance_class         = "db.t3.micro"
allocated_storage      = 100
engine_version         = "16"
# Removed invalid attribute "parameter_group_family"

# S3 Configuration
# bucket_name = "aws-dr-project-primary"
noncurrent_version_expiration_days = 30

# Common Settings
environment = "prod"
# region = "eu-west-1"
project_name = "aws-dr-project"

# Lambda Failover Settings
dr_region = "us-west-1"
# health_check_schedule = "rate(1 minute)"
# # log_retention_days = 30
# failover_threshold = 3

# DNS Settings
# ALB Configuration
alb_certificate_arn = ""
internal_alb        = true
# dns_name = "db.example.com"

# Monitoring Settings
# notification_topic_name = "dr-failover-notifications"

# Tags
tags = {
  Project     = "aws-dr-project"
  Environment = "prod"
  Region      = "Primary"
  Terraform   = "true"
  Owner       = "infrastructure-team"
}