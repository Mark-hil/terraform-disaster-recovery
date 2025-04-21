#!/bin/bash

# DR Failover Script
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

# Function to promote RDS read replica
promote_rds_replica() {
    local replica_id=$1
    echo "Promoting RDS read replica $replica_id to primary..."
    aws rds promote-read-replica \
        --db-instance-identifier "$replica_id" \
        --region "$DR_REGION"
}

# Function to update Route53 health check
update_route53_dns() {
    local primary_dns=$1
    local dr_dns=$2
    local hosted_zone_id=$3

    echo "Updating Route53 DNS records..."
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$hosted_zone_id" \
        --change-batch '{
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$primary_dns'",
                    "Type": "CNAME",
                    "TTL": 60,
                    "ResourceRecords": [{
                        "Value": "'$dr_dns'"
                    }]
                }
            }]
        }'
}

# Main failover process
echo "Starting DR failover process..."

# Get current configuration
DR_REGION=$(get_value dr_region)
DR_RDS_ID=$(get_value dr_rds_instance_id)
DR_RDS_ENDPOINT=$(get_value dr_rds_endpoint)
PRIMARY_DNS=$(get_value primary_dns)
HOSTED_ZONE_ID=$(get_value route53_zone_id)

# Confirm failover
echo "This will initiate failover to the DR region ($DR_REGION)."
echo "RDS replica to be promoted: $DR_RDS_ID"
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Failover cancelled."
    exit 0
fi

# Execute failover
echo "Executing failover..."

# 1. Promote RDS read replica
promote_rds_replica "$DR_RDS_ID"

# 2. Wait for promotion to complete
echo "Waiting for RDS promotion to complete..."
aws rds wait db-instance-available \
    --db-instance-identifier "$DR_RDS_ID" \
    --region "$DR_REGION"

# 3. Update DNS
update_route53_dns "$PRIMARY_DNS" "$DR_RDS_ENDPOINT" "$HOSTED_ZONE_ID"

echo "Failover complete! The application is now running in the DR region ($DR_REGION)."
echo "Please verify the application is functioning correctly in the DR region."
