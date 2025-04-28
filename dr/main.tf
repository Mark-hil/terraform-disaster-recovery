terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version              = "~> 4.0"
      configuration_aliases = [aws.primary, aws.dr]
    }
  }
}

data "aws_ami" "amazon_linux_2" {
  provider    = aws.dr
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get the existing RDS monitoring role from primary region
data "aws_iam_role" "rds_monitoring" {
  provider = aws.primary
  name     = "${var.environment}-rds-monitoring-role"
}

# Phase 1: Create IAM roles and policies
# Use the IAM module with primary region provider to access existing roles
module "iam" {
  source = "../modules/iam"
  providers = {
    aws = aws.primary  # Use primary region provider to access global IAM roles
  }

  environment = var.environment
  tags       = var.tags
  create_roles = false  # Use existing roles from primary region
  additional_ec2_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = "*"
    }
  ]
}

# Phase 2: Create RDS instance
# DR region will use the replica from primary region

# Phase 3: Create S3 bucket
module "dr_s3" {
  source = "../modules/s3"
  providers = {
    aws = aws
  }

  environment = var.environment
  project     = var.project_name
  kms_key_arn = var.kms_key_arn

  bucket_name       = "${var.environment}-${var.project_name}-replica"
  enable_versioning = true
  enable_encryption = true
}

# Network configuration
module "dr_vpc" {
  source = "../modules/network"
  providers = {
    aws = aws.dr
  }

  environment          = var.environment
  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  region              = var.dr_region
  availability_zones  = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
  tags               = var.tags
}

# RDS Read Replica
module "rds" {
  source = "../modules/rds"
  providers = {
    aws = aws.dr
  }

  environment               = var.environment
  skip_final_snapshot = true
  project_name              = var.project_name
  DB_NAME                   = var.DB_NAME
  DB_USER                   = var.DB_USER
  DB_PASSWORD               = var.DB_PASSWORD
  vpc_id                    = module.dr_vpc.vpc_id
  subnet_ids                = module.dr_vpc.private_subnet_ids
  security_group_ids        = [module.security_group.rds_security_group_id]
  monitoring_interval       = 60  # Enable enhanced monitoring
  monitoring_role_arn       = data.aws_iam_role.rds_monitoring.arn  # Use the existing role from primary region
  parameter_group_family    = "postgres16"
  tags                      = var.tags
  create_replica            = true
  primary_instance_arn      = var.primary_rds_arn
}

# AMI Replication
module "ami_replication" {
  source = "../modules/ami_replication"
  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  environment     = var.environment
  project_name   = var.project_name
  primary_region = var.primary_region
  dr_region      = var.dr_region
  primary_ec2_id = var.primary_instance_id
  lambda_role_arn = module.iam.ami_replication_lambda_role_arn
  tags           = var.tags
}

# Lambda Failover
module "lambda_failover" {
  source = "../modules/lambda_failover"
  providers = {
    aws    = aws.dr
    aws.dr = aws.dr
  }

  environment              = var.environment
  project_name             = var.project_name
  primary_region           = var.primary_region
  dr_region                = var.aws_region
  primary_ec2_ids          = var.primary_instance_ids
  dr_ec2_ids               = module.dr_ec2.instance_ids
  dr_rds_identifier        = module.rds.dr_id
  primary_alb_arn          = var.primary_alb_arn
  dr_alb_arn               = module.dr_alb.alb_arn
  primary_target_group_arn = var.primary_target_group_arn
  dr_target_group_arn      = module.dr_alb.target_group_arn
  primary_rds_id           = var.primary_rds_id
  notification_topic_arn   = var.notification_topic_arn

  tags = var.tags
}

# Security Group
module "security_group" {
  source = "../modules/security"
  providers = {
    aws           = aws.dr
    aws.primary   = aws.primary
    aws.dr        = aws.dr
    aws.dr_region = aws.dr
  }

  vpc_id       = module.dr_vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  tags = var.tags
}

# EC2 Instances
module "dr_ec2" {
  source = "../modules/ec2"
  providers = {
    aws = aws.dr
  }

  environment          = var.environment
  project_name        = var.project_name
  instance_count      = var.instance_count
  instance_type       = var.instance_type
  vpc_id             = module.dr_vpc.vpc_id
  subnet_ids          = module.dr_vpc.private_subnet_ids
  security_group_ids  = [module.security_group.app_security_group_id]
  instance_profile_name = module.iam.ec2_instance_profile_name
  root_volume_size   = var.root_volume_size
  tags              = var.tags
  instance_state    = "stopped"  # DR instances start in stopped state
  ami_id           = data.aws_ami.amazon_linux_2.id
  DB_NAME          = var.DB_NAME
  DB_USER          = var.DB_USER
  DB_PASSWORD      = var.DB_PASSWORD
  DB_HOST          = var.DB_HOST
}

# DR Application Load Balancer
module "dr_alb" {
  source = "../modules/alb"
  providers = {
    aws = aws.dr
  }

  environment   = var.environment
  name          = "${var.environment}-${var.project_name}-dr-app"
  vpc_id        = module.dr_vpc.vpc_id
  subnet_ids    = module.dr_vpc.public_subnet_ids
  instance_ids  = module.dr_ec2.instance_ids
  frontend_port = 3000
  backend_port  = 8000

  tags = var.tags
}

# Phase 5: Create CloudWatch alarms and dashboard
module "cloudwatch" {
  source = "../modules/cloudwatch"
  providers = {
    aws           = aws.dr
    aws.primary   = aws.primary
    aws.dr        = aws.dr
    aws.dr_region = aws.dr
  }

  environment          = var.environment
  project_name         = var.project_name
  region               = var.aws_region
  lambda_function_arn  = module.lambda_failover.function_arn
  lambda_function_name = module.lambda_failover.function_name
  alarm_topic_arns     = []
  primary_region       = var.primary_region
  dr_region            = var.aws_region
  dr_rds_id            = module.rds.dr_id
  tags                 = var.tags
}