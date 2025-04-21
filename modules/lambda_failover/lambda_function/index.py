import boto3
import os
import json
import time
from datetime import datetime

# Environment variables
PRIMARY_REGION = os.environ['PRIMARY_REGION']
DR_REGION = os.environ['DR_REGION']
PRIMARY_RDS_ID = os.environ['PRIMARY_RDS_ID']
DR_RDS_ID = os.environ['DR_RDS_ID']
PRIMARY_TG_ARN = os.environ['PRIMARY_TARGET_GROUP_ARN']
DR_TG_ARN = os.environ['DR_TARGET_GROUP_ARN']
ALB_ARN = os.environ['ALB_ARN']
PRIMARY_BUCKET = os.environ['PRIMARY_BUCKET']
DR_BUCKET = os.environ['DR_BUCKET']

# Initialize AWS clients
rds_primary = boto3.client('rds', region_name=PRIMARY_REGION)
rds_dr = boto3.client('rds', region_name=DR_REGION)
elb = boto3.client('elbv2', region_name=DR_REGION)
s3 = boto3.client('s3')
sns = boto3.client('sns')

def check_rds_health(region, instance_id):
    """Check the health of an RDS instance"""
    try:
        rds_client = boto3.client('rds', region_name=region)
        response = rds_client.describe_db_instances(DBInstanceIdentifier=instance_id)
        instance = response['DBInstances'][0]
        
        # Check instance status
        status = instance['DBInstanceStatus']
        if status != 'available':
            return False, f"RDS instance {instance_id} is in {status} state"
        
        return True, "RDS instance is healthy"
    except Exception as e:
        return False, f"Error checking RDS health: {str(e)}"

def check_s3_replication():
    """Check S3 replication status"""
    try:
        response = s3.get_bucket_replication(Bucket=PRIMARY_BUCKET)
        rules = response['ReplicationConfiguration']['Rules']
        
        for rule in rules:
            if rule['Status'] != 'Enabled':
                return False, f"S3 replication rule is {rule['Status']}"
        
        return True, "S3 replication is healthy"
    except Exception as e:
        return False, f"Error checking S3 replication: {str(e)}"

def promote_dr_instance():
    """Promote the DR RDS instance to primary"""
    try:
        response = rds_dr.promote_read_replica(DBInstanceIdentifier=DR_RDS_ID)
        return True, "Successfully initiated DR instance promotion"
    except Exception as e:
        return False, f"Error promoting DR instance: {str(e)}"

def update_alb_routing():
    """Update ALB routing to point to DR target group"""
    try:
        # Get the default listener (assuming HTTPS:443)
        response = elb.describe_listeners(LoadBalancerArn=ALB_ARN)
        listener_arn = response['Listeners'][0]['ListenerArn']
        
        # Update the listener rule to forward to DR target group
        response = elb.modify_listener(
            ListenerArn=listener_arn,
            DefaultActions=[
                {
                    'Type': 'forward',
                    'TargetGroupArn': DR_TG_ARN,
                    'Order': 1
                }
            ]
        )
        return True, "Successfully updated ALB routing"
    except Exception as e:
        return False, f"Error updating ALB routing: {str(e)}"

def send_notification(message, subject="DR Failover Alert"):
    """Send SNS notification"""
    try:
        topic_arn = os.environ.get('NOTIFICATION_TOPIC_ARN')
        if topic_arn:
            sns.publish(
                TopicArn=topic_arn,
                Message=message,
                Subject=subject
            )
    except Exception as e:
        print(f"Error sending notification: {str(e)}")

def handler(event, context):
    """Main Lambda handler"""
    try:
        # Check primary RDS health
        rds_healthy, rds_message = check_rds_health(PRIMARY_REGION, PRIMARY_RDS_ID)
        if not rds_healthy:
            send_notification(f"Primary RDS health check failed: {rds_message}")
            
            # Check S3 replication
            s3_healthy, s3_message = check_s3_replication()
            if not s3_healthy:
                send_notification(f"S3 replication check failed: {s3_message}")
            
            # Initiate failover
            promote_success, promote_message = promote_dr_instance()
            if promote_success:
                # Wait for promotion to complete
                time.sleep(30)  # Give some time for promotion to start
                
                # Get DR instance endpoint
                dr_response = rds_dr.describe_db_instances(DBInstanceIdentifier=DR_RDS_ID)
                dr_endpoint = dr_response['DBInstances'][0]['Endpoint']['Address']
                
                # Update ALB routing
                alb_success, alb_message = update_alb_routing()
                
                message = f"""
                DR Failover completed:
                - Primary RDS: {rds_message}
                - S3 Replication: {s3_message}
                - DR Promotion: {promote_message}
                - ALB Update: {alb_message}
                """
                send_notification(message, "DR Failover Completed")
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Failover completed successfully',
                        'timestamp': datetime.utcnow().isoformat()
                    })
                }
            else:
                message = f"Failover failed: {promote_message}"
                send_notification(message, "DR Failover Failed")
                raise Exception(message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Health check passed',
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except Exception as e:
        error_message = f"Error in DR failover process: {str(e)}"
        send_notification(error_message, "DR Failover Error")
        raise
