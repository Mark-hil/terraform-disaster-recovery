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
    aws         = aws
    aws.dr_region = aws.dr
  }

  environment            = var.environment
  database_name         = replace(lower("awsdrprojectdb"), "-", "")
  db_username           = var.db_username
  db_password           = var.db_password
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_ids    = [module.security_group.rds_security_group_id]
  monitoring_role_arn   = aws_iam_role.rds_monitoring.arn
  parameter_group_family = "mysql8.0"

  tags = var.tags
}

# Phase 3: Create S3 bucket
module "primary_s3" {
  source = "../modules/s3"
  providers = {
    aws = aws
  }

  environment = var.environment
  project     = var.project_name
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

# Phase 5: Create EC2 instances
module "primary_ec2" {
  source = "../modules/ec2"
  providers = {
    aws = aws
  }

  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.public_subnet_ids
  instance_type        = "t3.micro"
  instance_count       = 1
  security_group_ids   = [module.security_group.app_security_group_id]
  instance_profile_name = aws_iam_instance_profile.ec2_profile.name

  # Docker configuration
  docker_image    = "nginx:latest"  # You can change this to any Docker image
  container_port  = 80
  host_port       = 80

  tags = var.tags
}

# Phase 5: Create CloudWatch alarms and dashboard
module "cloudwatch" {
  source = "../modules/cloudwatch"
  providers = {
    aws = aws.primary
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  project_name = var.project_name
  environment = var.environment
  region = var.primary_region
  alarm_topic_arns = []

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

# Security Group
module "security_group" {
  source = "../modules/security"
  providers = {
    aws = aws.primary
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source = "../modules/alb"
  providers = {
    aws = aws.primary
  }

  environment = var.environment
  name        = "app"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  instance_ids = module.primary_ec2.instance_ids

  tags = var.tags
}

# Lambda Function for DR Failover
module "lambda_failover" {
  source = "../modules/lambda_failover"

  environment        = var.environment
  project_name      = var.project_name
  primary_region     = var.primary_region
  dr_region         = var.dr_region
  primary_ec2_ids   = module.primary_ec2.instance_ids
  dr_ec2_ids       = [var.dr_instance_id]
  dr_rds_identifier = "prod-awsdrprojectdb-dr-replica"
  
  primary_alb_arn   = module.alb.alb_arn
  dr_alb_arn       = var.dr_alb_arn
  primary_target_group_arn = module.alb.target_group_arn
  dr_target_group_arn     = var.dr_target_group_arn
  primary_rds_id   = module.primary_rds.primary_db_instance_id

  tags = local.tags

  providers = {
    aws = aws.primary
  }
}