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
PRIMARY_EC2_IDS = os.environ['PRIMARY_EC2_IDS'].split(',')
DR_EC2_IDS = os.environ['DR_EC2_IDS'].split(',')

# Initialize AWS clients
rds_primary = boto3.client('rds', region_name=PRIMARY_REGION)
rds_dr = boto3.client('rds', region_name=DR_REGION)
ec2_primary = boto3.client('ec2', region_name=PRIMARY_REGION)
ec2_dr = boto3.client('ec2', region_name=DR_REGION)
elb = boto3.client('elbv2', region_name=PRIMARY_REGION)
elb_dr = boto3.client('elbv2', region_name=DR_REGION)
sns = boto3.client('sns', region_name=PRIMARY_REGION)

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

def check_ec2_health(region, instance_ids):
    """Check the health of EC2 instances"""
    try:
        ec2_client = boto3.client('ec2', region_name=region)
        response = ec2_client.describe_instance_status(
            InstanceIds=instance_ids,
            IncludeAllInstances=True
        )
        
        unhealthy_instances = []
        for status in response['InstanceStatuses']:
            instance_id = status['InstanceId']
            instance_state = status['InstanceState']['Name']
            instance_status = status['InstanceStatus']['Status']
            system_status = status['SystemStatus']['Status']
            
            if (instance_state != 'running' or 
                instance_status != 'ok' or 
                system_status != 'ok'):
                unhealthy_instances.append(f"{instance_id} (State: {instance_state}, Instance: {instance_status}, System: {system_status})")
        
        if unhealthy_instances:
            return False, f"Unhealthy EC2 instances found: {', '.join(unhealthy_instances)}"
        
        return True, "All EC2 instances are healthy"
    except Exception as e:
        return False, f"Error checking EC2 health: {str(e)}"

def start_dr_instances():
    """Start DR EC2 instances if they're stopped"""
    try:
        stopped_instances = []
        response = ec2_dr.describe_instances(InstanceIds=DR_EC2_IDS)
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] == 'stopped':
                    stopped_instances.append(instance['InstanceId'])
        
        if stopped_instances:
            ec2_dr.start_instances(InstanceIds=stopped_instances)
            return True, f"Started DR instances: {', '.join(stopped_instances)}"
        
        return True, "All DR instances are already running"
    except Exception as e:
        return False, f"Error starting DR instances: {str(e)}"

def promote_dr_instance():
    """Promote the DR RDS instance to primary"""
    try:
        print(f"Attempting to promote DR instance: {DR_RDS_ID}")
        print(f"Using RDS client in region: {DR_REGION}")
        
        # Get current instance details
        instance_details = rds_dr.describe_db_instances(DBInstanceIdentifier=DR_RDS_ID)
        print(f"Current instance details: {json.dumps(instance_details, default=str)}")
        
        response = rds_dr.promote_read_replica(DBInstanceIdentifier=DR_RDS_ID)
        print(f"Promotion response: {json.dumps(response, default=str)}")
        return True, "Successfully initiated DR instance promotion"
    except Exception as e:
        error_details = str(e)
        print(f"Error promoting DR instance: {error_details}")
        return False, f"Error promoting DR instance: {error_details}"

def update_alb_routing():
    """Update ALB routing to point to DR target group"""
    try:
        # Get the default listener (assuming HTTPS:443)
        response = elb_dr.describe_listeners(LoadBalancerArn=ALB_ARN)
        listener_arn = response['Listeners'][0]['ListenerArn']
        
        # Update the listener rule to forward to DR target group
        response = elb_dr.modify_listener(
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
            timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
            formatted_message = f"Time: {timestamp}\n\n{message}\n\nEnvironment Details:\n" + \
                f"- Primary Region: {PRIMARY_REGION}\n" + \
                f"- DR Region: {DR_REGION}\n" + \
                f"- Primary RDS: {PRIMARY_RDS_ID}\n" + \
                f"- DR RDS: {DR_RDS_ID}"
            
            sns.publish(
                TopicArn=topic_arn,
                Message=formatted_message,
                Subject=subject
            )
            print(f"Notification sent: {subject}")
    except Exception as e:
        print(f"Error sending notification: {str(e)}")

def lambda_handler(event, context):
    """Main Lambda handler"""
    try:
        # Check primary RDS health
        rds_healthy, rds_message = check_rds_health(PRIMARY_REGION, PRIMARY_RDS_ID)
        
        # Check primary EC2 instances health
        ec2_healthy, ec2_message = check_ec2_health(PRIMARY_REGION, PRIMARY_EC2_IDS)
        
        if not rds_healthy or not ec2_healthy:
            send_notification(
                f"Health check failed:\n- RDS: {rds_message}\n- EC2: {ec2_message}"
            )
            
            # Start DR failover process
            # 1. Start DR EC2 instances if they're stopped
            start_success, start_message = start_dr_instances()
            
            # 2. Promote DR RDS instance
            promote_success, promote_message = promote_dr_instance()
            if promote_success:
                # Wait for promotion to complete
                time.sleep(30)  # Give some time for promotion to start
                
                # Get DR instance endpoint
                dr_response = rds_dr.describe_db_instances(DBInstanceIdentifier=DR_RDS_ID)
                dr_endpoint = dr_response['DBInstances'][0]['Endpoint']['Address']
                
                # 3. Update ALB routing
                alb_success, alb_message = update_alb_routing()
                
                message = f"""
                DR Failover completed:
                - Primary RDS: {rds_message}
                - Primary EC2: {ec2_message}
                - DR EC2 Start: {start_message}
                - DR RDS Promotion: {promote_message}
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
