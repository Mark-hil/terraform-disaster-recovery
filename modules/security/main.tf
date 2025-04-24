# Security Group Module

# Create RDS security group
resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-${var.project_name}-rds-"
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

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project_name}-rds"
  })
}

# Create application security group
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-${var.project_name}-app-"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # Frontend ingress rule
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.alb_security_group_id != null ? [var.alb_security_group_id] : []
    description     = "Allow HTTP access for frontend"
  }

  # Backend ingress rule
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = var.alb_security_group_id != null ? [var.alb_security_group_id] : []
    description     = "Allow HTTP access for backend"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
    description = "Allow SSH access from specific IPs"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP access from anywhere"
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
    Name = "${var.environment}-${var.project_name}-app"
  })
}
