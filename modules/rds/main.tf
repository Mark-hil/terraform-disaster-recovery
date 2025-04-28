# RDS Subnet Group
resource "aws_db_subnet_group" "primary" {
  name       = "${var.environment}-${var.project_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project_name}-subnet-group"
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "primary" {
  name        = "${var.environment}-primary-db-params"
  family      = var.parameter_group_family
  description = "Primary DB parameter group"



  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-primary-db-params"
  })
}

# Random password for RDS master user
resource "random_password" "master_password" {
  count   = var.create_replica ? 0 : 1
  length  = 16
  special = true
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-${var.project_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Primary RDS instance
resource "aws_db_instance" "primary" {
  skip_final_snapshot     = true
  count                   = var.create_replica ? 0 : 1
  identifier              = "${var.environment}-${var.project_name}db"
  engine                  = "postgres"
  engine_version          = "16.8"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  username                = var.DB_USER
  password                = coalesce(var.DB_PASSWORD, random_password.master_password[0].result)
  db_name                 = var.DB_NAME
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  parameter_group_name    = aws_db_parameter_group.primary.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  monitoring_interval     = var.monitoring_interval
  monitoring_role_arn     = var.monitoring_role_arn
  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project_name}db"
  })
}

# Read replica in DR region
resource "aws_db_instance" "dr_replica" {
  skip_final_snapshot        = true
  count                      = var.create_replica ? 1 : 0
  identifier                 = "${var.environment}-${var.project_name}db-dr-replica"
  replicate_source_db        = var.primary_instance_arn
  instance_class             = "db.t3.micro"
  vpc_security_group_ids     = [aws_security_group.rds.id]
  db_subnet_group_name       = aws_db_subnet_group.primary.name
  parameter_group_name       = aws_db_parameter_group.primary.name
  monitoring_interval        = var.monitoring_interval
  monitoring_role_arn        = var.monitoring_role_arn
  multi_az                   = false
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project_name}db-dr-replica"
  })
}

# Store database information in SSM Parameter Store
resource "aws_ssm_parameter" "DB_HOST" {
  name  = "/dr/${var.environment}/${var.project_name}/DB_HOST"
  type  = "String"
  value = var.create_replica ? aws_db_instance.dr_replica[0].endpoint : aws_db_instance.primary[0].endpoint
}

resource "aws_ssm_parameter" "DB_NAME" {
  name  = "/dr/${var.environment}/${var.project_name}/DB_NAME"
  type  = "String"
  value = var.DB_NAME
}

resource "aws_ssm_parameter" "DB_USER" {
  name  = "/dr/${var.environment}/${var.project_name}/DB_USER"
  type  = "String"
  value = var.DB_USER
}

resource "aws_ssm_parameter" "DB_PASSWORD" {
  name  = "/dr/${var.environment}/${var.project_name}/DB_PASSWORD"
  type  = "SecureString"
  value = var.DB_PASSWORD
}
