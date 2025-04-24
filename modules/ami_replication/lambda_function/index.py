import boto3
import os
import json
from datetime import datetime

def get_env_variables(ssm_client, environment, project_name):
    # Get environment variables from SSM Parameter Store
    try:
        response = ssm_client.get_parameter(
            Name=f'/dr/{environment}/{project_name}/env-vars',
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except ssm_client.exceptions.ParameterNotFound:
        print(f"No environment variables found in SSM for {environment}/{project_name}")
        return None

def update_env_file(instance_id, env_vars, ec2_client):
    if not env_vars:
        return
    
    # Create a temporary .env file
    with open('/tmp/.env', 'w') as f:
        f.write(env_vars)
    
    # Copy .env file to instance
    try:
        response = ec2_client.get_password_data(InstanceId=instance_id)
        if 'PasswordData' in response and response['PasswordData']:
            # Use AWS Systems Manager Session Manager to copy file
            ssm_client = boto3.client('ssm')
            response = ssm_client.send_command(
                InstanceIds=[instance_id],
                DocumentName='AWS-RunShellScript',
                Parameters={
                    'commands': [
                        'sudo cp /tmp/.env /app/.env',
                        'sudo chown ec2-user:ec2-user /app/.env',
                        'sudo chmod 600 /app/.env'
                    ]
                }
            )
            command_id = response['Command']['CommandId']
            
            # Wait for command completion
            waiter = ssm_client.get_waiter('command_executed')
            waiter.wait(
                CommandId=command_id,
                InstanceId=instance_id
            )
    except Exception as e:
        print(f"Error updating .env file: {str(e)}")

def lambda_handler(event, context):
    # Environment variables
    primary_region = os.environ['PRIMARY_REGION']
    dr_region = os.environ['DR_REGION']
    instance_id = os.environ['PRIMARY_INSTANCE_ID']
    environment = os.environ['ENVIRONMENT']
    project_name = os.environ['PROJECT_NAME']
    app_path = os.environ.get('APP_PATH', '/app')  # Default to /app if not specified

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
            Description=f"Daily backup of {instance_id} for DR",
            NoReboot=True  # Set to False if you want to ensure consistency but accept downtime
        )
        primary_ami_id = response['ImageId']

        # Wait for the AMI to be available
        print(f"Waiting for AMI {primary_ami_id} to be available")
        waiter = ec2_primary.get_waiter('image_available')
        waiter.wait(ImageIds=[primary_ami_id])

        # Copy AMI to DR region
        print(f"Copying AMI {primary_ami_id} to DR region {dr_region}")
        copy_response = ec2_dr.copy_image(
            SourceImageId=primary_ami_id,
            SourceRegion=primary_region,
            Name=f"DR-{ami_name}",
            Description=f"DR copy of {ami_name}",
            Encrypted=True
        )
        dr_ami_id = copy_response['ImageId']

        # Tag the DR AMI
        print(f"Tagging DR AMI {dr_ami_id}")
        ec2_dr.create_tags(
            Resources=[dr_ami_id],
            Tags=[
                {'Key': 'Name', 'Value': f"DR-{ami_name}"},
                {'Key': 'Environment', 'Value': environment},
                {'Key': 'Project', 'Value': project_name},
                {'Key': 'SourceAMI', 'Value': primary_ami_id},
                {'Key': 'CreatedOn', 'Value': timestamp}
            ]
        )

        # Clean up old AMIs in DR region (keep last 7 days)
        print("Cleaning up old DR AMIs")
        amis = ec2_dr.describe_images(
            Filters=[
                {'Name': 'name', 'Values': [f"DR-{environment}-{project_name}-*"]},
                {'Name': 'tag:Environment', 'Values': [environment]}
            ],
            Owners=['self']
        )['Images']
        
        # Sort AMIs by creation date
        amis.sort(key=lambda x: x['CreationDate'], reverse=True)
        
        # Keep only the 7 most recent AMIs
        for ami in amis[7:]:
            print(f"Deregistering old AMI {ami['ImageId']}")
            ec2_dr.deregister_image(ImageId=ami['ImageId'])

        # Get environment variables from SSM
        ssm = boto3.client('ssm', region_name=dr_region)
        env_vars = get_env_variables(ssm, environment, project_name)
        
        # Wait for the instance to be ready
        print(f"Waiting for DR instance {dr_ami_id} to be available")
        waiter = ec2_dr.get_waiter('instance_running')
        waiter.wait(InstanceIds=[instance_id])
        
        # Update .env file if we have environment variables
        if env_vars:
            print("Updating .env file on DR instance")
            update_env_file(instance_id, env_vars, ec2_dr)
        
        # Store the latest AMI ID in SSM Parameter Store
        ssm.put_parameter(
            Name=f'/dr/{environment}/{project_name}/latest-ami',
            Value=dr_ami_id,
            Type='String',
            Overwrite=True
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'PrimaryAMI': primary_ami_id,
                'DRAMI': dr_ami_id,
                'Message': 'AMI replication completed successfully'
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        raise
