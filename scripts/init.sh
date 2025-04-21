#!/bin/bash

# Initialize Terraform for AWS DR Project
set -e

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "Error: AWS credentials not configured. Please configure AWS credentials first."
    exit 1
fi

# Create S3 bucket for Terraform state if it doesn't exist
BUCKET_NAME="${PROJECT_NAME:-aws-dr-project}-terraform-state"
REGION="${PRIMARY_REGION:-eu-west-1}"

if ! aws s3 ls "s3://$BUCKET_NAME" 2>&1 > /dev/null; then
    echo "Creating S3 bucket for Terraform state..."
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration \
        '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
fi

# Create DynamoDB table for state locking if it doesn't exist
TABLE_NAME="${PROJECT_NAME:-aws-dr-project}-terraform-locks"

if ! aws dynamodb describe-table --table-name "$TABLE_NAME" &>/dev/null; then
    echo "Creating DynamoDB table for state locking..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION"
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init \
    -backend-config="bucket=$BUCKET_NAME" \
    -backend-config="key=aws-dr-project/terraform.tfstate" \
    -backend-config="region=$REGION" \
    -backend-config="dynamodb_table=$TABLE_NAME"

echo "Initialization complete!"
