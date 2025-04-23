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
  db_username = var.db_username
  db_password = var.db_password
  db_host = var.db_host
  kms_key_arn = var.dr_kms_key_arn
  tags = var.tags

  providers = {
    aws = aws.dr
    aws.primary = aws.primary
    aws.dr = aws.dr
  }

  depends_on = [module.base_infrastructure]
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
  db_username = var.db_username
  db_password = var.db_password
  db_host = var.db_host
  kms_key_arn = var.kms_key_arn
  dr_kms_key_arn = var.dr_kms_key_arn
  tags = var.tags

  # Pass DR module outputs
  dr_instance_id      = module.dr.dr_instance_id
  dr_alb_arn          = module.dr.dr_alb_arn
  dr_target_group_arn = module.dr.dr_target_group_arn

  providers = {
    aws = aws.primary
    aws.primary = aws.primary
    aws.dr = aws.dr
  }

  depends_on = [module.dr]
}
