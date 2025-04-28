#!/bin/bash

echo "🚀 Starting Terraform infrastructure deployment..."

# Initialize Terraform if not already initialized
if [ ! -d ".terraform" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
fi

# Format the Terraform files
echo "🎨 Formatting Terraform files..."
terraform fmt -recursive

# Validate the Terraform files
echo "✅ Validating Terraform configuration..."
terraform validate

if [ $? -eq 0 ]; then
    echo "🔍 Running Terraform plan..."
    terraform plan -out=tfplan

    if [ $? -eq 0 ]; then
        echo "⚡ Applying Terraform changes..."
        terraform apply tfplan
        
        if [ $? -eq 0 ]; then
            echo "✨ Infrastructure successfully deployed!"
        else
            echo "❌ Failed to apply Terraform changes"
            exit 1
        fi
    else
        echo "❌ Terraform plan failed"
        exit 1
    fi
else
    echo "❌ Terraform validation failed"
    exit 1
fi
