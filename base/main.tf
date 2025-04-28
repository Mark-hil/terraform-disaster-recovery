# Base infrastructure module for multi-region VPC setup

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.dr]
    }
  }
}

# Primary VPC
module "primary_vpc" {
  source = "../modules/network"
  providers = {
    aws = aws.primary
  }

  environment          = var.environment
  project_name        = var.project_name
  vpc_cidr            = var.primary_vpc_cidr
  region              = var.primary_region
  availability_zones  = var.primary_azs
  private_subnet_cidrs = var.primary_private_subnet_cidrs
  public_subnet_cidrs = var.primary_public_subnet_cidrs
  tags               = var.tags
}

# DR VPC
module "dr_vpc" {
  source = "../modules/network"
  providers = {
    aws = aws.dr
  }

  environment          = var.environment
  project_name        = var.project_name
  vpc_cidr            = var.dr_vpc_cidr
  region              = var.dr_region
  availability_zones  = var.dr_azs
  private_subnet_cidrs = var.dr_private_subnet_cidrs
  public_subnet_cidrs = var.dr_public_subnet_cidrs
  tags               = var.tags
}
