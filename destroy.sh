#!/bin/bash

set -e

echo "Step 1: Deleting Lambda Function..."
aws lambda delete-function \
  --function-name prod-dr-failover \
  --region eu-west-1 || true

echo "Step 2: Deleting Load Balancer and Target Groups..."
# Delete ALB
if aws elbv2 describe-load-balancers --names prod-dr-alb --region eu-west-1 2>/dev/null; then
  echo "Deleting ALB..."
  ALB_ARN=$(aws elbv2 describe-load-balancers --names prod-dr-alb --region eu-west-1 --query 'LoadBalancers[0].LoadBalancerArn' --output text)
  aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --region eu-west-1
  sleep 30
fi

# Delete target groups
if aws elbv2 describe-target-groups --names prod-primary-tg --region eu-west-1 2>/dev/null; then
  echo "Deleting primary target group..."
  aws elbv2 delete-target-group \
    --target-group-arn $(aws elbv2 describe-target-groups --names prod-primary-tg --region eu-west-1 --query 'TargetGroups[0].TargetGroupArn' --output text) \
    --region eu-west-1
fi

if aws elbv2 describe-target-groups --names prod-dr-tg --region us-east-1 2>/dev/null; then
  echo "Deleting DR target group..."
  aws elbv2 delete-target-group \
    --target-group-arn $(aws elbv2 describe-target-groups --names prod-dr-tg --region us-east-1 --query 'TargetGroups[0].TargetGroupArn' --output text) \
    --region us-east-1
fi

echo "Step 3: Deleting IAM Role..."
# Detach policies
aws iam detach-role-policy \
  --role-name prod-us-east-1-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole || true

aws iam delete-role-policy \
  --role-name prod-us-east-1-lambda-role \
  --policy-name prod-lambda-policy || true

# Delete role
aws iam delete-role \
  --role-name prod-us-east-1-lambda-role || true

echo "Step 4: Running Terraform Destroy..."
terraform destroy -auto-approve

echo "Cleanup complete!"
