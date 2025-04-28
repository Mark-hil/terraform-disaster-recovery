#!/bin/bash

set -e

echo "⚠️ WARNING: This script will destroy all infrastructure resources!"
echo "You have 10 seconds to cancel (Ctrl+C)..."

for i in {10..1}; do
    echo -ne "\rDestroying in $i seconds..."
    sleep 1
done
echo -e "\n"

echo "Step 1: Deleting Lambda Functions and Roles..."
# Delete Lambda functions in both regions
aws lambda delete-function \
  --function-name prod-dr-failover \
  --region eu-west-1 || true

aws lambda delete-function \
  --function-name prod-dr-failover \
  --region us-east-1 || true

# Clean up Lambda roles and policies
echo "Cleaning up Lambda IAM roles..."
ROLES=("prod-eu-west-1-lambda-role" "prod-us-east-1-lambda-role")
REGIONS=("eu-west-1" "us-east-1")

for role in "${ROLES[@]}"; do
  # Detach managed policies
  for policy in $(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyArn' --output text); do
    echo "Detaching policy $policy from role $role"
    aws iam detach-role-policy --role-name "$role" --policy-arn "$policy" || true
  done

  # Delete inline policies
  for policy in $(aws iam list-role-policies --role-name "$role" --query 'PolicyNames[*]' --output text); do
    echo "Deleting inline policy $policy from role $role"
    aws iam delete-role-policy --role-name "$role" --policy-name "$policy" || true
  done

  # Delete role
  echo "Deleting role $role"
  aws iam delete-role --role-name "$role" || true
done

echo "Step 2: Cleaning up Parameter Store..."
# Delete parameters in both regions
for region in "${REGIONS[@]}"; do
  echo "Cleaning up parameters in $region"
  # Project's Parameter Store paths
  PARAMS=(
    "/dr/prod/aws-dr-project/db-endpoint"
    "/dr/prod/aws-dr-project/db-name"
    "/dr/prod/aws-dr-project/db-password"
    "/dr/prod/aws-dr-project/db-username"
    "/dr/prod/aws-dr-project/latest-ami"
    "/dr/prod/aws-dr-project/env-vars"
  )

  for param in "${PARAMS[@]}"; do
    echo "Deleting parameter $param in $region"
    aws ssm delete-parameter --name "$param" --region "$region" || true
  done
done

echo "Step 3: Deleting Load Balancer and Target Groups..."
# Delete ALBs in both regions
for region in "${REGIONS[@]}"; do
  if aws elbv2 describe-load-balancers --names prod-dr-alb --region "$region" 2>/dev/null; then
    echo "Deleting ALB in $region..."
    ALB_ARN=$(aws elbv2 describe-load-balancers --names prod-dr-alb --region "$region" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$region"
    sleep 30
  fi

  # Delete target groups
  if aws elbv2 describe-target-groups --names prod-primary-tg --region "$region" 2>/dev/null; then
    echo "Deleting primary target group in $region..."
    aws elbv2 delete-target-group \
      --target-group-arn $(aws elbv2 describe-target-groups --names prod-primary-tg --region "$region" --query 'TargetGroups[0].TargetGroupArn' --output text) \
      --region "$region"
  fi

  if aws elbv2 describe-target-groups --names prod-dr-tg --region "$region" 2>/dev/null; then
    echo "Deleting DR target group in $region..."
    aws elbv2 delete-target-group \
      --target-group-arn $(aws elbv2 describe-target-groups --names prod-dr-tg --region "$region" --query 'TargetGroups[0].TargetGroupArn' --output text) \
      --region "$region"
  fi
done

echo "Step 4: Running Terraform Destroy..."
terraform destroy -auto-approve

echo "✨ Cleanup complete!"
