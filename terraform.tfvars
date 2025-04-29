# Project Settings
project_name = "aws-dr-project"
environment  = "prod"

# Region Settings
primary_region = "eu-west-1"
dr_region      = "us-east-1"

# Primary Region Network Settings
primary_vpc_cidr = "10.0.0.0/16"
primary_azs = [
  "eu-west-1a",
  "eu-west-1b"
]
primary_private_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]
primary_public_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]

# DR Region Network Settings
dr_vpc_cidr = "10.1.0.0/16"
dr_azs = [
  "us-east-1a",
  "us-east-1b"
]
dr_private_subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24"
]
dr_public_subnet_cidrs = [
  "10.1.101.0/24",
  "10.1.102.0/24"
]

# Database Configuration
DB_NAME     = "chat_db"
DB_USER     = "postgres"
DB_PASSWORD = "postgres123"
DB_HOST     = "" # Will be populated by RDS endpoint

# RDS Settings
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 10

# ALB Configuration
# This will be replaced by your actual certificate ARN
# alb_certificate_arn = ""

# Common Tags
tags = {
  Project     = "aws-dr-project"
  Environment = "prod"
  Terraform   = "true"
  Owner       = "infrastructure-team"
}