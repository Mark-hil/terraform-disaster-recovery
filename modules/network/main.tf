terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name = "${var.environment}-${var.project_name}-vpc"
    },
    var.tags
  )
}

# Create VPC endpoints for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.vpc_endpoints.id]
  subnet_ids         = aws_subnet.private[*].id

  private_dns_enabled = true

  tags = {
    Name        = "${var.environment}-ssm-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.vpc_endpoints.id]
  subnet_ids         = aws_subnet.private[*].id

  private_dns_enabled = true

  tags = {
    Name        = "${var.environment}-ssmmessages-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.vpc_endpoints.id]
  subnet_ids         = aws_subnet.private[*].id

  private_dns_enabled = true

  tags = {
    Name        = "${var.environment}-ec2messages-endpoint"
    Environment = var.environment
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.environment}-vpc-endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name        = "${var.environment}-vpc-endpoints"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = min(length(var.public_subnet_cidrs), length(var.availability_zones))
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.environment}-${var.project_name}-public-${count.index + 1}"
    },
    var.tags
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = min(length(var.private_subnet_cidrs), length(var.availability_zones))
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name = "${var.environment}-${var.project_name}-private-${count.index + 1}"
    },
    var.tags
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.environment}-${var.project_name}-igw"
    },
    var.tags
  )
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    {
      Name = "${var.environment}-${var.project_name}-public-rt"
    },
    var.tags
  )
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.environment}-${var.project_name}-private-rt-${count.index + 1}"
    },
    var.tags
  )
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}