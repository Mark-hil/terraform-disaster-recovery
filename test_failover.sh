#!/bin/bash

echo "Step 1: Getting Resource Information..."
# Get the EC2 instance ID
PRIMARY_INSTANCE_ID=$(aws ec2 describe-instances \
  --region eu-west-1 \
  --filters "Name=tag:Environment,Values=prod" "Name=tag:Project,Values=aws-dr-project" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

echo "Step 2: Testing EC2 Failover..."
aws ec2 stop-instances --instance-ids $PRIMARY_INSTANCE_ID --region eu-west-1

echo "Step 3: Simulating Primary RDS Failure..."
# Stop the primary RDS instance to simulate failure
aws rds stop-db-instance \
  --db-instance-identifier prod-awsdrprojectdb \
  --region eu-west-1

echo "Step 4: Invoking Lambda Failover Function..."
# Invoke Lambda to handle failover (this will promote the read replica)
aws lambda invoke \
  --function-name prod-dr-failover \
  --region eu-west-1 \
  --payload '{}' \
  response.json

echo "Failover test response:"
cat response.json

echo "Failover test complete! The read replica in us-east-1 should now be promoted to primary."
