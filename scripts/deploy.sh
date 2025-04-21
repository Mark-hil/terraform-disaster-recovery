#!/bin/bash

# Deploy AWS DR Infrastructure
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

# Set workspace
echo "Setting Terraform workspace to $ENVIRONMENT..."
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

# Plan the deployment
echo "Planning deployment for $ENVIRONMENT environment..."
terraform plan \
    -var-file="terraform.tfvars" \
    -var="environment=$ENVIRONMENT" \
    -out=tfplan

# Ask for confirmation
read -p "Do you want to apply these changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Apply the changes
    echo "Applying changes..."
    terraform apply tfplan

    # Clean up the plan file
    rm tfplan

    echo "Deployment complete!"
else
    echo "Deployment cancelled."
    rm tfplan
    exit 0
fi
