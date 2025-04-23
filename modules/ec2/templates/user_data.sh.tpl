#!/bin/bash

# Update system packages
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Run the Docker container
docker run -d \
  --name app \
  -p ${host_port}:${container_port} \
  --restart always \
  ${docker_image}

# Add CloudWatch agent for monitoring (optional)
yum install -y amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
