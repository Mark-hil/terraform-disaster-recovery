# Primary VPC
module "primary_vpc" {
  source = "../modules/network"
  providers = {
    aws = aws.primary
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  environment  = var.environment
  region      = var.primary_region
  vpc_cidr     = var.primary_vpc_cidr
  availability_zones = var.primary_azs
  private_subnet_cidrs = var.primary_private_subnet_cidrs
  public_subnet_cidrs = var.primary_public_subnet_cidrs
  tags = var.tags
}

# DR VPC
module "dr_vpc" {
  source = "../modules/network"
  providers = {
    aws = aws.dr
    aws.primary = aws.primary
    aws.dr = aws.dr
    aws.dr_region = aws.dr
  }

  environment  = var.environment
  region      = var.dr_region
  vpc_cidr     = var.dr_vpc_cidr
  availability_zones = var.dr_azs
  private_subnet_cidrs = var.dr_private_subnet_cidrs
  public_subnet_cidrs = var.dr_public_subnet_cidrs
  tags = var.tags
}
