#!/bin/bash

# Cleanup Script for AWS DR Infrastructure
set -e

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "Error: AWS credentials not configured. Please configure AWS credentials first."
    exit 1
fi

# Function to validate environment
validate_env() {
    if [[ ! "$1" =~ ^(dev|staging|prod)$ ]]; then
        echo "Error: Invalid environment. Must be one of: dev, staging, prod"
        exit 1
    fi
}

# Parse command line arguments
ENVIRONMENT=${1:-prod}
validate_env "$ENVIRONMENT"

# Warning message
echo "WARNING: This will destroy all DR infrastructure in the $ENVIRONMENT environment!"
echo "This includes:"
echo "  - RDS instances and replicas"
echo "  - S3 buckets and their contents"
echo "  - VPC and networking components"
echo "  - IAM roles and policies"
echo "  - CloudWatch alarms"

# Require explicit confirmation
echo
echo "To proceed, please type the environment name ($ENVIRONMENT) in all caps:"
read -r confirmation

if [ "$confirmation" != "${ENVIRONMENT^^}" ]; then
    echo "Confirmation did not match. Aborting cleanup."
    exit 1
fi

# Set workspace
echo "Setting Terraform workspace to $ENVIRONMENT..."
terraform workspace select "$ENVIRONMENT"

# Destroy infrastructure
echo "Destroying infrastructure..."
terraform destroy \
    -var-file="terraform.tfvars" \
    -var="environment=$ENVIRONMENT" \
    -auto-approve

echo "Cleanup complete!"
