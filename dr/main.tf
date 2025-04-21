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
  name               = "${var.environment}-${var.aws_region}-ec2-role"
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
  name = "${var.environment}-${var.aws_region}-ec2-profile"
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
  name = "${var.environment}-ec2-policy"
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

# Phase 5: Create EC2 instances
module "dr_ec2" {
  source = "../modules/ec2"
  providers = {
    aws = aws
  }

  environment = var.environment
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  instance_type = "t3.micro"
  instance_count = 1
  security_group_ids = [module.security_group.app_security_group_id]
  instance_profile_name = aws_iam_instance_profile.ec2_profile.name

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = "DR"
  })

  depends_on = [module.dr_s3]
}

# Phase 5: Create CloudWatch alarms and dashboard
module "cloudwatch" {
  source = "../modules/cloudwatch"
  providers = {
    aws = aws.dr
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  project_name = var.project_name
  environment = var.environment
  region = var.aws_region
  alarm_topic_arns = []

  tags = var.tags
}

# Network configuration
module "vpc" {
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

# Security Group
module "security_group" {
  source = "../modules/security"
  providers = {
    aws = aws.dr
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = "DR"
  })
}