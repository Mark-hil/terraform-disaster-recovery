# Phase 1: Create base infrastructure (VPCs)
# Base infrastructure module
module "base_infrastructure" {
  source = "./base"

  environment = var.environment
  project_name = var.project_name
  primary_region = var.primary_region
  dr_region = var.dr_region
  primary_vpc_cidr = var.primary_vpc_cidr
  dr_vpc_cidr = var.dr_vpc_cidr
  primary_azs = var.primary_azs
  dr_azs = var.dr_azs
  primary_private_subnet_cidrs = var.primary_private_subnet_cidrs
  primary_public_subnet_cidrs = var.primary_public_subnet_cidrs
  dr_private_subnet_cidrs = var.dr_private_subnet_cidrs
  dr_public_subnet_cidrs = var.dr_public_subnet_cidrs
  kms_key_arn = var.kms_key_arn
  dr_kms_key_arn = var.dr_kms_key_arn
  tags = var.tags

  providers = {
    aws.primary = aws.primary
    aws.dr = aws.dr
  }
}

# Phase 2: Create primary region resources
# Primary module
module "primary" {
  source = "./primary"

  environment = var.environment
  project_name = var.project_name
  primary_region = var.primary_region
  dr_region = var.dr_region
  vpc_cidr = var.primary_vpc_cidr
  availability_zones = var.primary_azs
  private_subnet_cidrs = var.primary_private_subnet_cidrs
  public_subnet_cidrs = var.primary_public_subnet_cidrs
  kms_key_arn = aws_kms_key.primary.arn
  dr_kms_key_arn = aws_kms_key.dr.arn
  DB_NAME = var.DB_NAME
  DB_USER = var.DB_USER
  DB_PASSWORD = var.DB_PASSWORD
  DB_HOST = var.DB_HOST
  dr_instance_id = "i-dummy"
  dr_alb_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/dummy/dummy"
  dr_target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/dummy/dummy"
  tags = var.tags

  providers = {
    aws = aws
    aws.primary = aws
    aws.dr = aws.dr
  }

  depends_on = [module.base_infrastructure]
}

# Phase 3: Create DR region resources
# DR module
module "dr" {
  source = "./dr"

  environment = var.environment
  project_name = var.project_name
  aws_region = var.dr_region
  primary_region = var.primary_region
  dr_region = var.dr_region
  vpc_cidr = var.dr_vpc_cidr
  availability_zones = var.dr_azs
  private_subnet_cidrs = var.dr_private_subnet_cidrs
  public_subnet_cidrs = var.dr_public_subnet_cidrs
  DB_NAME = var.DB_NAME
  DB_USER = var.DB_USER
  DB_PASSWORD = var.DB_PASSWORD
  DB_HOST = var.DB_HOST
  kms_key_arn = var.dr_kms_key_arn
  primary_rds_arn = module.primary.rds_arn
  tags = var.tags

  # Pass primary module outputs
  primary_instance_id = module.primary.primary_instance_id
  primary_instance_ids = module.primary.primary_instance_ids
  primary_alb_arn = module.primary.primary_alb_arn
  primary_target_group_arn = module.primary.primary_target_group_arn
  primary_rds_id = module.primary.primary_rds_id
  notification_topic_arn = module.primary.notification_topic_arn

  providers = {
    aws = aws.dr
    aws.primary = aws.primary
    aws.dr = aws.dr
  }

  depends_on = [module.primary]
}
