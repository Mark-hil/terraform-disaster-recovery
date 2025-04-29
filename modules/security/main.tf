# Security Group Module

# Create RDS security group
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg-${random_id.suffix.hex}"
  description = "Security group for RDS instances"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # Allow PostgreSQL access only from the application security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "Allow PostgreSQL access from application instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

# Create application security group
# Random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg-${random_id.suffix.hex}"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # Allow inbound traffic from ALB for frontend
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow frontend access from ALB"
  }

  # Allow inbound traffic from ALB for backend
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow backend access from ALB"
  }

  # Allow SSH access for EC2 Instance Connect
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access for EC2 Instance Connect"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-app-sg"
  })
}

# Create ALB security group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg-${random_id.suffix.hex}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # Allow inbound HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  # Allow inbound traffic for backend port
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow backend traffic"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-alb-sg"
  })
}
