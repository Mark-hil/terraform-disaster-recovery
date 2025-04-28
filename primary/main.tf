terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.dr]
    }
  }
}

data "aws_ami" "amazon_linux_2" {
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

# Phase 1: Create S3 bucket
module "s3" {
  source = "../modules/s3"
  providers = {
    aws = aws
  }

  environment       = var.environment
  project           = var.project_name
  bucket_name       = "${var.environment}-${var.project_name}-primary"
  kms_key_arn       = var.kms_key_arn
  enable_versioning = true
  enable_encryption = true

  tags = var.tags
}

# IAM roles and policies
module "iam" {
  source = "../modules/iam"
  providers = {
    aws = aws.primary
  }

  environment = var.environment
  tags       = var.tags
  create_roles = true  # Create roles in primary region
  additional_ec2_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:DescribeLoadBalancers"
      ]
      Resource = "*"
    }
  ]
  source_bucket_arn      = module.s3.s3_bucket_arn
  destination_bucket_arn = var.dr_bucket_arn
}

# Phase 2: Create RDS instance
module "primary_rds" {
  source = "../modules/rds"
  providers = {
    aws = aws
  }

  skip_final_snapshot = true
  environment            = var.environment
  project_name           = var.project_name
  DB_NAME                = var.DB_NAME
  DB_USER                = var.DB_USER
  DB_PASSWORD            = var.DB_PASSWORD
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [module.security_group.rds_security_group_id]
  monitoring_interval    = 60  # Enable enhanced monitoring
  monitoring_role_arn    = module.iam.rds_monitoring_role_arn
  parameter_group_family = "postgres16"
  tags                   = var.tags
  create_replica         = false
}

# Create security groups
module "security_group" {
  source = "../modules/security"
  providers = {
    aws = aws
  }

  environment             = var.environment
  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  ssh_allowed_cidr_blocks = var.ssh_allowed_cidr_blocks
  tags                    = var.tags
}

# Phase 5: Create EC2 instances and replicate AMI
module "primary_ec2" {
  source = "../modules/ec2"
  providers = {
    aws = aws.primary
  }

  environment          = var.environment
  project_name        = var.project_name
  instance_count      = var.instance_count
  instance_type       = var.instance_type
  vpc_id             = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [module.security_group.app_security_group_id]
  instance_profile_name = module.iam.ec2_instance_profile_name
  root_volume_size   = var.root_volume_size
  tags              = var.tags
  instance_state    = "running"
  ami_id           = data.aws_ami.amazon_linux_2.id
  DB_NAME          = var.DB_NAME
  DB_USER          = var.DB_USER
  DB_PASSWORD      = var.DB_PASSWORD
  DB_HOST          = module.primary_rds.rds_endpoint
}

# AMI Replication
module "ami_replication" {
  source = "../modules/ami_replication"
  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  environment     = var.environment
  project_name    = var.project_name
  primary_region  = var.primary_region
  dr_region       = var.dr_region
  primary_ec2_id  = module.primary_ec2.instance_ids[0]
  lambda_role_arn = module.iam.ami_replication_lambda_role_arn
  tags           = var.tags
}

# Phase 5: Create CloudWatch alarms and dashboard
module "cloudwatch" {
  source = "../modules/cloudwatch"
  providers = {
    aws           = aws
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
  primary_region       = var.aws_region
  dr_region            = var.dr_region
  dr_rds_id            = module.primary_rds.dr_id
  tags                 = var.tags
}

# Network configuration
module "vpc" {
  source = "../modules/network"
  providers = {
    aws           = aws.primary
    aws.primary   = aws.primary
    aws.dr        = aws.dr
    aws.dr_region = aws.dr
  }

  environment          = var.environment
  project_name = var.project_name
  region               = var.primary_region
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  tags                 = var.tags
}

# Application Load Balancer
module "alb" {
  source = "../modules/alb"
  providers = {
    aws = aws.primary
  }

  environment                = var.environment
  name                       = "app"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  instance_ids               = module.primary_ec2.instance_ids
  target_type                = "instance"
  frontend_port              = 3000
  backend_port               = 8000
  health_check_path_frontend = "/"
  health_check_path_backend  = "/admin/"

  tags = var.tags
}

# SNS Topic for Notifications
module "sns" {
  source = "../modules/sns"
  providers = {
    aws = aws
  }

  environment  = var.environment
  project_name = var.project_name
  tags         = var.tags
}

# Lambda Function for DR Failover
module "lambda_failover" {
  source = "../modules/lambda_failover"
  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  environment              = var.environment
  project_name             = var.project_name
  primary_region           = var.aws_region
  dr_region                = var.dr_region
  primary_ec2_ids          = module.primary_ec2.instance_ids
  dr_ec2_ids               = [var.dr_instance_id]
  dr_rds_identifier        = module.primary_rds.dr_id
  primary_alb_arn          = module.alb.alb_arn
  dr_alb_arn               = var.dr_alb_arn
  primary_target_group_arn = module.alb.frontend_target_group_arn
  dr_target_group_arn      = var.dr_target_group_arn
  primary_rds_id           = module.primary_rds.primary_id
  notification_topic_arn   = module.sns.topic_arn

  tags = var.tags
}