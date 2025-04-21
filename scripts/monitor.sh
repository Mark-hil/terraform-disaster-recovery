#!/bin/bash

# DR Monitoring Script
set -e

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "Error: AWS credentials not configured. Please configure AWS credentials first."
    exit 1
fi

# Function to get resource values
get_value() {
    terraform output -raw "$1"
}

# Function to check RDS replication lag
check_rds_replication() {
    local replica_id=$1
    local region=$2
    
    echo "Checking RDS replication lag..."
    aws cloudwatch get-metric-statistics \
        --namespace AWS/RDS \
        --metric-name ReplicaLag \
        --dimensions Name=DBInstanceIdentifier,Value="$replica_id" \
        --start-time "$(date -u -v-5M '+%Y-%m-%dT%H:%M:%SZ')" \
        --end-time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --period 300 \
        --statistics Average \
        --region "$region"
}

# Function to check S3 replication
check_s3_replication() {
    local bucket=$1
    local region=$2
    
    echo "Checking S3 replication metrics..."
    aws s3api get-bucket-metrics-configuration \
        --bucket "$bucket" \
        --id replication \
        --region "$region"
}

# Main monitoring process
echo "Starting DR monitoring..."

# Get resource information
DR_REGION=$(get_value dr_region)
DR_RDS_ID=$(get_value dr_rds_instance_id)
DR_S3_BUCKET=$(get_value dr_s3_bucket)

# Check RDS replication
echo -e "\n=== RDS Replication Status ==="
check_rds_replication "$DR_RDS_ID" "$DR_REGION"

# Check S3 replication
echo -e "\n=== S3 Replication Status ==="
check_s3_replication "$DR_S3_BUCKET" "$DR_REGION"

# Check CloudWatch alarms
echo -e "\n=== CloudWatch Alarms Status ==="
aws cloudwatch describe-alarms \
    --state-value ALARM \
    --region "$DR_REGION"

echo -e "\nMonitoring complete!"
