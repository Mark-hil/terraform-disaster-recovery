terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
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