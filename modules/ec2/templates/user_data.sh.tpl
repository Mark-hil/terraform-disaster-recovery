#!/bin/bash

# ===========================================
# User Data Script for Chat Application Setup
# ===========================================

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "[1/7] Starting user data script execution..."

# ===========================================
# System Updates and Dependencies
# ===========================================
echo "[2/7] Installing system dependencies..."

# Update system packages
yum update -y

# Install SSM agent
yum install -y \
    https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

# Start and enable SSM agent
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Install required packages
yum install -y \
    docker \
    aws-cli \
    jq \
    nc \
    curl

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
echo "[3/7] Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# ===========================================
# Application Setup
# ===========================================
echo "[4/7] Setting up application directory..."

# Create and move to app directory
mkdir -p /app
cd /app

# Set application configuration
FRONTEND_IMAGE="markhill97/chat-app-frontend:v1.1"
BACKEND_IMAGE="markhill97/chat-app-backend:v1.0"
FRONTEND_PORT=3000
BACKEND_PORT=8000


# Get instance metadata
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

# Get load balancer DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerArn, `app`)].DNSName' --output text)

# ===========================================
# Database Configuration
# ===========================================
echo "[5/7] Configuring database connection..."

# Parse database connection details
if [[ ${DB_HOST} == *:* ]]; then
    DB_PORT=$(echo ${DB_HOST} | cut -d: -f2)
    DB_HOST=$(echo ${DB_HOST} | cut -d: -f1)
else
    DB_PORT=5432
fi

echo "Database connection: $DB_HOST:$DB_PORT"

# Wait for database availability
echo "Waiting for database connection..."
until nc -z $DB_HOST $DB_PORT; do
    echo "Database not ready, retrying in 5 seconds..."
    sleep 5
done
echo "Database connection established!"

# ===========================================
# Docker Configuration
# ===========================================
echo "[6/7] Setting up Docker containers..."

# Clean up existing containers and images
echo "Cleaning up existing containers and images..."
docker ps -aq | xargs -r docker stop
docker ps -aq | xargs -r docker rm
docker images -q $FRONTEND_IMAGE | xargs -r docker rmi -f
docker images -q $BACKEND_IMAGE | xargs -r docker rmi -f

# Pull latest images
echo "Pulling Docker images..."
docker pull $FRONTEND_IMAGE || { echo "Failed to pull frontend image"; exit 1; }
docker pull $BACKEND_IMAGE || { echo "Failed to pull backend image"; exit 1; }

# Create docker-compose.yml
cat > docker-compose.yml << EOL
version: '3.8'

services:
  frontend:
    container_name: chat-frontend
    image: $FRONTEND_IMAGE
    ports:
      - "$FRONTEND_PORT:$FRONTEND_PORT"
    environment:
      - VITE_API_BASE_URL=http://chatapp-api.amalitech-dev.net
      - PORT=$FRONTEND_PORT
      - HOST=0.0.0.0
      - NODE_ENV=production
    restart: unless-stopped
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    container_name: chat-backend
    image: $BACKEND_IMAGE
    ports:
      - "$BACKEND_PORT:$BACKEND_PORT"
    environment:
      - DB_HOST=$DB_HOST
      - DB_PORT=$DB_PORT
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - ALLOWED_HOSTS=chatapp.amalitech-dev.net,localhost,127.0.0.1,*
      - CORS_ALLOWED_ORIGINS=http://chatapp.amalitech-dev.net,http://localhost:$FRONTEND_PORT,*
      - DJANGO_SETTINGS_MODULE=chat_project.settings
    restart: unless-stopped
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:$BACKEND_PORT"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  app-network:
    driver: bridge
EOL

# ===========================================
# Application Startup
# ===========================================
echo "[7/7] Starting application..."

# Start containers
docker-compose up -d

# Wait for database to be ready
echo "Waiting for database to be ready..."
until nc -z $DB_HOST $DB_PORT; do
    echo "Database not ready yet, waiting..."
    sleep 5
done
echo "Database is ready!"

# Wait for backend to be healthy
echo "Waiting for backend to be healthy..."
until [ "$(docker inspect --format='{{.State.Health.Status}}' chat-backend)" = "healthy" ]; do
    echo "Backend not healthy yet, waiting..."
    sleep 5
done
echo "Backend is healthy!"

# Apply database migrations
echo "Applying database migrations..."
docker exec chat-backend python manage.py migrate
echo "Database migrations applied successfully!"

# Verify deployment
echo "\nContainer Status:"
docker ps

echo "\nContainer Logs:"
docker-compose logs

echo "\n✅ User data script completed successfully!"
echo "Frontend should be available at http://$ALB_DNS:$FRONTEND_PORT"
echo "Backend should be available at http://$ALB_DNS:$BACKEND_PORT"

echo "Using database connection: $DB_HOST:$DB_PORT"

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
