# Phase 1: Create IAM roles and policies
# RDS monitoring role
resource "aws_iam_role" "rds_monitoring" {
  name               = "${var.environment}-${var.aws_region}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  description = "Allows RDS to manage enhanced monitoring metrics"
}

# Attach RDS monitoring policy
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# EC2 role
resource "aws_iam_role" "ec2_role" {
  name               = "${var.environment}-${var.project_name}-${var.aws_region}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  description = "Allows EC2 to access required services"
}

# Attach EC2 policies
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_secrets" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# EC2 instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-${var.project_name}-${var.aws_region}-ec2-profile"
  role = aws_iam_role.ec2_role.name
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

  bucket_name = "${var.environment}-${var.project_name}-replica"
  enable_versioning = true
  enable_encryption = true
}

# Phase 4: Update IAM policies with resource ARNs
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.environment}-${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.dr_s3.s3_bucket_arn,
          "${module.dr_s3.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Network configuration
module "dr_vpc" {
  source = "../modules/network"
  providers = {
    aws = aws.dr
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  environment = var.environment
  region = var.dr_region
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
  tags = var.tags
}

# First create security groups
module "security_group" {
  source = "../modules/security"
  providers = {
    aws = aws.dr
  }

  vpc_id       = module.dr_vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name
  alb_security_group_id = null

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = "DR"
  })
}

# Then create ALB
module "dr_alb" {
  source = "../modules/alb"
  project_name = var.project_name
  providers = {
    aws = aws.dr
  }

  name        = "${var.environment}-${var.project_name}-dr"
  vpc_id      = module.dr_vpc.vpc_id
  environment = var.environment
  subnet_ids  = module.dr_vpc.public_subnet_ids
  target_security_group_ids = [module.security_group.app_security_group_id]

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = "DR"
  })
}

# Update security group with ALB security group ID
resource "aws_security_group_rule" "alb_to_app" {
  provider                 = aws.dr
  type                    = "ingress"
  from_port               = 80
  to_port                 = 80
  protocol                = "tcp"
  source_security_group_id = module.dr_alb.alb_security_group_id
  security_group_id       = module.security_group.app_security_group_id
}

# Then create RDS
module "rds" {
  source = "../modules/rds"
  providers = {
    aws = aws.dr
  }

  environment = var.environment
  project_name = var.project_name
  DB_NAME = var.DB_NAME
  DB_USER = var.DB_USER
  DB_PASSWORD = var.DB_PASSWORD
  vpc_id = module.dr_vpc.vpc_id
  subnet_ids = module.dr_vpc.private_subnet_ids
  security_group_ids = [module.security_group.rds_security_group_id]
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  parameter_group_family = "postgres16"
  tags = var.tags
  create_replica = true
  primary_instance_arn = var.primary_rds_arn
}

# Finally create EC2 instances
module "dr_ec2" {
  source = "../modules/ec2"
  providers = {
    aws = aws.dr
  }

  environment = var.environment
  project_name = var.project_name
  vpc_id = module.dr_vpc.vpc_id
  instance_count = 1
  instance_type = "t3.micro"
  subnet_ids = module.dr_vpc.private_subnet_ids
  security_group_ids = [module.security_group.app_security_group_id]
  instance_profile_name = aws_iam_instance_profile.ec2_profile.name
  instance_state = "stopped"
  root_volume_size = 20
  DB_NAME = var.DB_NAME
  DB_USER = var.DB_USER
  DB_PASSWORD = var.DB_PASSWORD
  DB_HOST = module.rds.rds_endpoint
}

# Finally attach EC2 instances to ALB target groups
resource "aws_lb_target_group_attachment" "app" {
  provider         = aws.dr
  count           = length(module.dr_ec2.instance_ids)
  target_group_arn = module.dr_alb.target_group_arn
  target_id        = module.dr_ec2.instance_ids[count.index]
  port            = 80
}

# AMI Replication
module "ami_replication" {
  source = "../modules/ami_replication"
  providers = {
    aws = aws.dr
    aws.dr = aws.dr
  }

  environment = var.environment
  project_name = var.project_name
  primary_region = var.primary_region
  dr_region = var.dr_region
  source_instance_id = var.primary_instance_id
  primary_instance_id = var.primary_instance_id
  env_vars = jsonencode({
    FRONTEND_IMAGE = "markhill97/chat-app-frontend:latest"
    BACKEND_IMAGE  = "markhill97/chat-app-backend:latest"
    FRONTEND_PORT  = "3000"
    BACKEND_PORT   = "8000"
  })
  tags = var.tags
}

# Lambda Failover
module "lambda_failover" {
  source = "../modules/lambda_failover"
  providers = {
    aws = aws.dr
    aws.dr = aws.dr
  }

  environment = var.environment
  project_name = var.project_name
  primary_region = var.primary_region
  dr_region = var.aws_region
  primary_ec2_ids = var.primary_instance_ids
  dr_ec2_ids = module.dr_ec2.instance_ids
  dr_rds_identifier = module.rds.dr_id
  primary_alb_arn = var.primary_alb_arn
  dr_alb_arn = module.dr_alb.alb_arn
  primary_target_group_arn = var.primary_target_group_arn
  dr_target_group_arn = module.dr_alb.target_group_arn
  primary_rds_id = var.primary_rds_id
  notification_topic_arn = var.notification_topic_arn

  tags = var.tags
}

# CloudWatch alarms and dashboard
module "cloudwatch" {
  source = "../modules/cloudwatch"
  providers = {
    aws = aws.dr
  }

  primary_instance_id = module.dr_ec2.instance_ids[0]
  primary_rds_id = module.rds.dr_id
  environment = var.environment
  project_name = var.project_name
  region = var.aws_region
  lambda_function_arn = module.lambda_failover.function_arn
  lambda_function_name = module.lambda_failover.function_name
  alarm_topic_arns = []
  primary_region = var.primary_region
  dr_region = var.aws_region
  dr_rds_id = module.rds.dr_id
  tags = var.tags
}