import os
import boto3
from datetime import datetime

def lambda_handler(event, context):
    # Environment variables
    primary_region = os.environ['PRIMARY_REGION']
    dr_region = os.environ['DR_REGION']
    instance_id = os.environ['PRIMARY_EC2_ID']
    environment = os.environ['ENVIRONMENT']
    project_name = os.environ['PROJECT_NAME']

    try:
        # Create EC2 client for primary region
        ec2_primary = boto3.client('ec2', region_name=primary_region)
        ec2_dr = boto3.client('ec2', region_name=dr_region)

        # Create AMI in primary region
        timestamp = datetime.utcnow().strftime('%Y%m%d-%H%M%S')
        ami_name = f"{environment}-{project_name}-{timestamp}"
        
        print(f"Creating AMI {ami_name} from instance {instance_id}")
        response = ec2_primary.create_image(
            InstanceId=instance_id,
            Name=ami_name,
            Description=f"AMI created from {instance_id} for disaster recovery",
            NoReboot=True
        )
        
        source_ami_id = response['ImageId']
        print(f"Created AMI {source_ami_id} in {primary_region}")
        
        # Wait for the AMI to be available
        waiter = ec2_primary.get_waiter('image_available')
        waiter.wait(ImageIds=[source_ami_id])
        
        # Copy AMI to DR region
        copy_response = ec2_dr.copy_image(
            SourceImageId=source_ami_id,
            SourceRegion=primary_region,
            Name=f"{ami_name}-dr",
            Description=f"DR copy of AMI {source_ami_id}"
        )
        
        dr_ami_id = copy_response['ImageId']
        print(f"Copied AMI to {dr_region} with ID {dr_ami_id}")
        
        # Tag the DR AMI
        ec2_dr.create_tags(
            Resources=[dr_ami_id],
            Tags=[
                {'Key': 'Environment', 'Value': environment},
                {'Key': 'Project', 'Value': project_name},
                {'Key': 'SourceAMI', 'Value': source_ami_id},
                {'Key': 'ManagedBy', 'Value': 'terraform'}
            ]
        )
        
        return {
            'statusCode': 200,
            'body': {
                'message': 'AMI replication completed successfully',
                'sourceAmiId': source_ami_id,
                'drAmiId': dr_ami_id
            }
        }
        
    except Exception as e:
        print(f"Error during AMI replication: {str(e)}")
        raise
