terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
      configuration_aliases = [aws.primary, aws.dr]
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Default provider configuration for primary region
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
      Owner       = "infrastructure-team"
    }
  }
}

# Primary region provider
provider "aws" {
  alias  = "primary"
  region = var.primary_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
      Owner       = "infrastructure-team"
    }
  }
}

# DR region provider
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
      Owner       = "infrastructure-team"
    }
  }
}