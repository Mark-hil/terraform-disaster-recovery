### Delete IAM Roles
echo "Deleting IAM roles..."
for role in \
  prod-ami-replication-lambda-role \
  prod-dr-failover-lambda-role \
  prod-us-east-1-ami-replication-lambda-role; do

  echo "Deleting IAM Role: $role"
  
  # Detach all attached policies
  attached_policies=$(aws iam list-attached-role-policies \
    --role-name "$role" \
    --query 'AttachedPolicies[].PolicyArn' \
    --output text --profile $AWS_PROFILE --region $AWS_REGION 2>/dev/null)

  for policy_arn in $attached_policies; do
    echo " Detaching policy $policy_arn"
    aws iam detach-role-policy \
      --role-name "$role" \
      --policy-arn "$policy_arn" \
      --profile $AWS_PROFILE --region $AWS_REGION
  done

  # Delete inline policies
  inline_policies=$(aws iam list-role-policies \
    --role-name "$role" \
    --query 'PolicyNames[]' \
    --output text --profile $AWS_PROFILE --region $AWS_REGION 2>/dev/null)

  for policy_name in $inline_policies; do
    echo " Deleting inline policy $policy_name"
    aws iam delete-role-policy \
      --role-name "$role" \
      --policy-name "$policy_name" \
      --profile $AWS_PROFILE --region $AWS_REGION
  done

  # Delete the role
  aws iam delete-role --role-name "$role" --profile $AWS_PROFILE --region $AWS_REGION 2>/dev/null
done

echo "IAM roles deleted successfully."
