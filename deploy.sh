#!/bin/bash

set -e

echo "Step 1: Preparing Lambda Function..."
cd modules/lambda_failover/lambda_function
zip -r ../lambda_function.zip *
cd ../../../

echo "Step 2: Deploying Infrastructure..."
terraform init
terraform apply -auto-approve

echo "Deployment complete! The DR environment is now ready."
