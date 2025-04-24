# Create IAM roles and policies
# RDS monitoring role
resource "aws_iam_role" "rds_monitoring" {
  name               = "${var.environment}-${var.primary_region}-rds-monitoring-role"
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
  name               = "${var.environment}-${var.primary_region}-ec2-role"
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

# Create EC2 instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-${var.primary_region}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Create S3 replication role
resource "aws_iam_role" "s3_replication" {
  name               = "${var.environment}-${var.primary_region}-s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
  description = "Allows S3 to replicate objects to DR region"
}

# Create S3 replication policy
resource "aws_iam_policy" "s3_replication" {
  name        = "${var.environment}-${var.primary_region}-s3-replication-policy"
  description = "Allows S3 to replicate objects to DR region"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach S3 replication policy to role
resource "aws_iam_role_policy_attachment" "s3_replication" {
  role       = aws_iam_role.s3_replication.name
  policy_arn = aws_iam_policy.s3_replication.arn
}

# Phase 2: Create RDS instance
module "primary_rds" {
  source = "../modules/rds"
  providers = {
    aws = aws
  }

  environment = var.environment
  project_name = var.project_name
  DB_NAME = var.DB_NAME
  DB_USER = var.DB_USER
  DB_PASSWORD = var.DB_PASSWORD
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [module.security_group.rds_security_group_id]
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  parameter_group_family = "postgres16"
  tags = var.tags
  create_replica = false
}

# Phase 3: Create S3 bucket
module "primary_s3" {
  source = "../modules/s3"
  providers = {
    aws = aws
  }

  environment = var.environment
  project = var.project_name
  bucket_name = "${var.environment}-${var.project_name}-primary"
  kms_key_arn = var.kms_key_arn
  enable_versioning = true
  enable_encryption = true

  tags = var.tags
}

# Phase 4: Update IAM policies with resource ARNs
resource "aws_iam_role_policy" "primary_s3_replication" {
  name = "${var.environment}-s3-replication-policy"
  role = aws_iam_role.s3_replication.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = module.primary_s3.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${module.primary_s3.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "arn:aws:s3:::prod-aws-dr-project-dr-replica/*"
      }
    ]
  })

  depends_on = [module.primary_s3]
}

# Security Groups
module "security_group" {
  source = "../modules/security"
  providers = {
    aws = aws.primary
  }

  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name
  alb_security_group_id = module.alb.alb_security_group_id

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = "Primary"
  })
}

# Phase 5: Create EC2 instances and replicate AMI
module "primary_ec2" {
  source = "../modules/ec2"
  providers = {
    aws = aws.primary
  }

  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  instance_count = 1
  instance_type = "t3.micro"
  subnet_ids = module.vpc.public_subnet_ids
  security_group_ids = [module.security_group.app_security_group_id]
  instance_profile_name = aws_iam_instance_profile.ec2_profile.name
  instance_state = "running"
  root_volume_size = 20

  dr_ami_parameter = ""
  frontend_image = "markhill97/chat-app-frontend:latest"
  backend_image = "markhill97/chat-app-backend:latest"
  frontend_port = 3000
  backend_port = 8000
  DB_HOST = module.primary_rds.rds_endpoint
  DB_NAME = var.DB_NAME
  DB_USER = var.DB_USER
  DB_PASSWORD = var.DB_PASSWORD

  tags = var.tags
}

# AMI Replication
module "ami_replication" {
  source = "../modules/ami_replication"
  providers = {
    aws = aws
    aws.dr = aws.dr
  }

  environment = var.environment
  project_name = var.project_name
  primary_region = var.aws_region
  dr_region = var.dr_region
  source_instance_id = module.primary_ec2.instance_ids[0]
  primary_instance_id = module.primary_ec2.instance_ids[0]
  env_vars = jsonencode({
    FRONTEND_IMAGE = "markhill97/chat-app-frontend:latest"
    BACKEND_IMAGE = "markhill97/chat-app-backend:latest"
    FRONTEND_PORT = "3000"
    BACKEND_PORT = "8000"
  })
  tags = var.tags
}

# Phase 5: Create CloudWatch alarms and dashboard
module "cloudwatch" {
  source = "../modules/cloudwatch"
  providers = {
    aws = aws.primary
  }

  primary_instance_id = module.primary_ec2.instance_ids[0]
  primary_rds_id = module.primary_rds.primary_instance_id
  environment = var.environment
  project_name = var.project_name
  region = var.aws_region
  lambda_function_arn = module.lambda_failover.function_arn
  lambda_function_name = module.lambda_failover.function_name
  alarm_topic_arns = []
  primary_region = var.aws_region
  dr_region = var.dr_region
  dr_rds_id = module.primary_rds.dr_id
  tags = var.tags
}

# Network configuration
module "vpc" {
  source = "../modules/network"
  providers = {
    aws = aws.primary
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  environment = var.environment
  region = var.primary_region
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source = "../modules/alb"
  project_name = var.project_name
  providers = {
    aws = aws.primary
  }

  name        = "${var.environment}-${var.project_name}-primary"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  subnet_ids  = module.vpc.public_subnet_ids
  target_security_group_ids = [module.security_group.app_security_group_id]

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = "Primary"
  })
}

# Create target group attachments
resource "aws_lb_target_group_attachment" "app" {
  provider         = aws.primary
  count           = length(module.primary_ec2.instance_ids)
  target_group_arn = module.alb.target_group_arn
  target_id        = module.primary_ec2.instance_ids[count.index]
  port            = 80
}

# SNS Topic for failover notifications
resource "aws_sns_topic" "failover" {
  provider = aws.primary
  name     = "${var.environment}-${var.project_name}-failover"
  tags     = merge(var.tags, {
    Name        = "${var.environment}-${var.project_name}-failover"
    Environment = var.environment
  })
}

# SNS Topic for Notifications
module "sns" {
  source = "../modules/sns"
  providers = {
    aws = aws
  }

  environment = var.environment
  project_name = var.project_name
  tags = var.tags
}

# Lambda Function for DR Failover
module "lambda_failover" {
  source = "../modules/lambda"
  providers = {
    aws = aws.primary
  }

  environment = var.environment
  project_name = var.project_name
  primary_instance_id = module.primary_ec2.instance_ids[0]
  dr_instance_id = var.dr_instance_id
  primary_rds_arn = module.primary_rds.rds_arn
  dr_rds_arn = var.dr_rds_arn
  primary_target_group_arn = module.alb.target_group_arn
  dr_target_group_arn = var.dr_target_group_arn
  sns_topic_arn = aws_sns_topic.failover.arn

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = "Primary"
  })
}