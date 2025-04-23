#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${GREEN}=== Primary Region (eu-west-1) ===${NC}"
echo -e "\n${BLUE}EC2 Instances:${NC}"
aws ec2 describe-instances \
  --region eu-west-1 \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress,Type:InstanceType}' \
  --output table

echo -e "\n${BLUE}Load Balancer:${NC}"
aws elbv2 describe-load-balancers \
  --region eu-west-1 \
  --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' \
  --output table

echo -e "\n${BLUE}Target Groups:${NC}"
aws elbv2 describe-target-groups \
  --region eu-west-1 \
  --query 'TargetGroups[].{Name:TargetGroupName,Port:Port,Protocol:Protocol}' \
  --output table

echo -e "\n${GREEN}=== DR Region (us-east-1) ===${NC}"
echo -e "\n${BLUE}EC2 Instances:${NC}"
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress,Type:InstanceType}' \
  --output table

echo -e "\n${BLUE}Load Balancer:${NC}"
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' \
  --output table

echo -e "\n${BLUE}Target Groups:${NC}"
aws elbv2 describe-target-groups \
  --region us-east-1 \
  --query 'TargetGroups[].{Name:TargetGroupName,Port:Port,Protocol:Protocol}' \
  --output table

echo -e "\n${BLUE}Testing Primary Application:${NC}"
PRIMARY_ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region eu-west-1 \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

if [ ! -z "$PRIMARY_ALB_DNS" ]; then
  echo "Waiting for application to be ready..."
  sleep 10
  curl -I "http://$PRIMARY_ALB_DNS"
fi
