#!/bin/bash

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script execution..."

# Update system packages
yum update -y

# Install AWS CLI and jq
yum install -y aws-cli jq

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p /app

# Get RDS endpoint and credentials from SSM Parameter Store
DB_HOST=$(aws ssm get-parameter --name "/dr/${environment}/${project_name}/DB_HOST" --with-decryption --query "Parameter.Value" --output text)
DB_NAME=$(aws ssm get-parameter --name "/dr/${environment}/${project_name}/DB_NAME" --with-decryption --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/dr/${environment}/${project_name}/DB_USER" --with-decryption --query "Parameter.Value" --output text)
DB_PASSWORD=$(aws ssm get-parameter --name "/dr/${environment}/${project_name}/DB_PASSWORD" --with-decryption --query "Parameter.Value" --output text)

# Extract port from DB_HOST if it contains a port, otherwise use default PostgreSQL port
if [[ $DB_HOST == *:* ]]; then
    DB_PORT=$(echo $DB_HOST | cut -d: -f2)
    DB_HOST=$(echo $DB_HOST | cut -d: -f1)
else
    DB_PORT=5432
fi

echo "Using database connection: $DB_HOST:$DB_PORT"

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Get load balancer DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerArn, `prod-app`)].DNSName' --output text)

# Install netcat for database connection check
yum install -y nc

# Stop and remove any existing containers
echo "Stopping and removing existing containers..."
docker ps -aq | xargs -r docker stop
docker ps -aq | xargs -r docker rm

# Wait for the database to be available
echo "Waiting for database to be available..."
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
done
echo "Database is available"

# Start the backend container
echo "Starting backend container..."
docker run -d \
  --name backend \
  -p $backend_port:8000 \
  -e DB_HOST=$DB_HOST \
  -e DB_PORT=$DB_PORT \
  -e DB_NAME=${DB_NAME} \
  -e DB_USER=${DB_USER} \
  -e DB_PASSWORD=${DB_PASSWORD} \
  -e ALLOWED_HOSTS="*" \
  --restart unless-stopped \
  $backend_image

# Wait for the backend to start
echo "Waiting for backend to start..."
while ! curl -s http://localhost:$backend_port/admin/ > /dev/null; do
  sleep 1
done
echo "Backend is available"

# Apply database migrations
echo "Applying database migrations..."
docker exec backend python manage.py migrate

# Start the frontend container
echo "Starting frontend container..."
docker run -d \
  --name frontend \
  -p $frontend_port:3000 \
  -e REACT_APP_BACKEND_URL=http://$ALB_DNS:$backend_port \
  -e PORT=3000 \
  -e HOST=0.0.0.0 \
  --restart unless-stopped \
  $frontend_image

echo "Application deployment completed"

# Tag the instance as ready
aws ec2 create-tags \
  --region $REGION \
  --resources $INSTANCE_ID \
  --tags Key=Status,Value=Ready

echo "User data script completed successfully"
