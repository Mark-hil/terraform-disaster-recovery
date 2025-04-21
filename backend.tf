# terraform {
#   required_version = ">= 1.0.0"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 4.0.0"
#     }
#   }

#   backend "s3" {
#     bucket         = "${var.project_name}-terraform-state"
#     key            = "aws-dr-project/terraform.tfstate"
#     region         = var.primary_region
#     dynamodb_table = "${var.project_name}-terraform-locks"
#     encrypt        = true
#   }
# }
