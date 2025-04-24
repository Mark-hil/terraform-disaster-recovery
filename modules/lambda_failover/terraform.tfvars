# Lambda Module Example Configuration

# Project Information
project_name = "aws-dr-project"
primary_region = "eu-west-1"
dr_region = "us-west-1"

# RDS Instance IDs
primary_rds_id = "aws-dr-project-primary"
dr_rds_id = "aws-dr-project-replica"

# ALB Configuration
primary_target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:targetgroup/primary/abc123"
dr_target_group_arn = "arn:aws:elasticloadbalancing:us-west-1:123456789012:targetgroup/dr/def456"
alb_arn = "arn:aws:elasticloadbalancing:us-west-1:123456789012:loadbalancer/app/dr/ghi789"

# S3 Bucket Names
primary_bucket_name = "aws-dr-project-primary"
dr_bucket_name = "aws-dr-project-replica"

# Health Check Configuration
health_check_schedule = "rate(1 minute)"  # CloudWatch Events schedule expression
failover_threshold = 3                    # Number of failures before failover

# Monitoring Configuration
log_retention_days = 30
notification_topic_arn = "arn:aws:sns:eu-west-1:123456789012:dr-failover-notifications"

# Resource Tags
tags = {
  Project     = "aws-dr-project"
  Environment = "prod"
  Component   = "dr-failover"
  Terraform   = "true"
  Owner       = "infrastructure-team"
}
